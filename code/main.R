#  script: main.R
#  purpose: download environmental data and create a relational database table
# Get Current Path
setwd("~/Documents/ECAD/ECADownloader/code")

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
cat("Number of core(s):",numCores)

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
mappingTotal <- list()
totalMap <- lapply(mapFile[,Index],ManipulateMapping)
totalMap <- rbindlist(totalMap)
setnames(totalMap, tolower(names(totalMap)))

# Upload stations 
dbWriteTable(conn  = conn,
             name  = c("tran_ler","station"),
             value = totalMap,
             overwrite = TRUE,
             row.names = F)

dbWriteTable(conn  = conn,
             name  = c("tran_ler","links"),
             value = linkMap,
             overwrite = TRUE,
             row.names = F)
cat("Uploaded variables information and links tables successfully\n")
