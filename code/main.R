#  script: main.R
#  purpose: download environmental data and create a relational database table

# Source functions
source("src.R")
source("srcSQL.R")

# Load configurator library
library(configr)
config <- read.config(file ="config.yml")

# Obtain all required packages
systemPackages <- config[["packages"]]

# Identify new packages
newPackages <- systemPackages[!(systemPackages %in% installed.packages(lib.loc = .libPaths()[1])[,"Package"])]

# Install new packages
if(length(newPackages)) install.packages(newPackages)

checkPackage <- lapply(systemPackages, require, character.only = TRUE, lib = .libPaths()[1], quietly = TRUE)

# Establish connection with DB using SQLServe
conn <- GetConnections(config)

# Obtain status of meteorological variables
listOfIndices <- names(config[["indices"]])
indexStatus   <- lapply(listOfIndices, function(x){ config[["indices"]][[x]] } ) 
mapFile       <- data.table(Index = listOfIndices, Status = indexStatus)
mapFile       <- copy(mapFile[Status == TRUE])

# Compute Number of Splits
numCores <- min(config[["default"]][["num_cores"]], mapFile[, .N])
cat("Number of core(s):",numCores,"\n")

splits   <- ceiling(mapFile[, .N]/ min(c(numCores, mapFile[, .N])))
mapFile[,Core:=rep(1:numCores, each=splits)]
cat("Approximately each core is responsible for downloading",splits,"index/indices \n")

# Get link dataset
linkMap <- GetLink(blendedID = config[["default"]][["blended"]], currPath = getwd())

# Downlod Data Using Multithreading
ExecuteDownloadData(process = config[["default"]][["download_data"]],
                    config,
                    getwd(),
                    numCores,
                    linkMap,
                    mapFile,
                    ParallelDownloadData,
                    DownloadData
)

# Preparing the database tables
linkMap <- copy(prepareDB(config,
                          linkMap,
                          dropSchema     = config[["default"]][["drop_schema"]],
                          createSchema   = config[["default"]][["create_schema"]],
                          createEmptyTbl = config[["default"]][["create_empty_tables"]])
)

# Get Stations Information
totalMap <- lapply(mapFile[,Index],ManipulateMapping)
totalMap <- rbindlist(totalMap)
setnames(totalMap, c("souid","souname","cn","latupd","lonupd","latlong","start","stop","metvar"))

# Upload stations 
dbWriteTable(conn  = conn,
             name  = c("tran_ler","station"),
             value = totalMap,
             overwrite = TRUE,
             row.names = F)
setnames(linkMap, c("varname", "link", "map", "id", "downloaddatalink", "downloadstationlink","downloaddatapath","createtablescript"))
dbWriteTable(conn  = conn,
             name  = c("tran_ler","links"),
             value = linkMap,
             overwrite = TRUE,
             row.names = F)
cat("Uploaded available variables and links tables successfully \n")

# Prepare paths and variables
uploadMapper <- copy(linkMap[varname %in% mapFile[,Index], 
        
        list(
          fileID = list.files(path = downloaddatapath, pattern = paste0("^",id))
        ),
        by = list(varname,downloaddatapath, id)
        ])

# Parallelise Tasks
uniqueComb <- uploadMapper[,.N]
splits <-  ceiling(uniqueComb/config[["default"]][["num_cores"]])
uploadMapper[,Core:=rep(1:config[["default"]][["num_cores"]], each=splits)[1:nrow(uploadMapper)]]
uploadMapper[, Counter:= 1:.N]

cl <- makeCluster(config[["default"]][["num_cores"]])
registerDoParallel(cl)
foreach(core_id=1:config[["default"]][["num_cores"]], .verbose = T, .packages=c("data.table")) %dopar%
  ParallelUploadData(config, coreID = core_id, uploadMapper, UploadFiles)
stopCluster(cl)


