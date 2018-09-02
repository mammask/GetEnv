GetConnections <- function(config){
  
  conn <- dbConncetor(dbType     = config[["database_config"]][["type"]],
                      dbNameID   = config[["database_config"]][["database_name"]],
                      hostID     = config[["database_config"]][["localhost"]],
                      port       = config[["database_config"]][["port"]],
                      usernameID = config[["database_config"]][["username"]],
                      passwordID = config[["database_config"]][["password"]]
  )
  # library(DBI)
  # drv <- dbDriver(config[["database_config"]][["driver"]])
  # conDf <- dbConnect(drv,
  #                    dbname   = config[["database_config"]][["database_name"]],
  #                    user     = config[["database_config"]][["username"]],
  #                    password = config[["database_config"]][["password"]],
  #                    host     = config[["database_config"]][["localhost"]]
  # )
  
  return(conn)
}


# Source Functions
GetLink <- function(blendedID, currPath){
  
  if (blendedID==TRUE) {  blendStat <- "ECA_blend" } else { blendStat <- "ECA_nonblend"}
  
  ## Define Base Download Link for Meteorological Data
  baseLinkDat <- "http://www.ecad.eu/utils/downloadfile.php?file=download/"
  
  ## Define Base Download Link for Mateorological Stations Information Map
  baseLinkMap <- "http://www.ecad.eu/download/"
  
  ## Define Link Map
  linkMap <-  data.table(VarName=c("DailyMaxTemp", "DailyMinTemp",
                                   "DailyMeanTemp", "DailyPrecipAmount",
                                   "DailyMeanSeaLVLPress","DailyCloudCover",
                                   "DailyHumid", "DailySnowDepth", 
                                   "DailySunShineDur","DailyMeanWindSpeed",
                                   "DailyMaxWindGust","DailyWindDirection"),
                         
                         Link=c("_tx.zip",
                                "_tn.zip",
                                "_tg.zip",
                                "_rr.zip",
                                "_pp.zip",
                                "_cc.zip",
                                "_hu.zip",
                                "_sd.zip",
                                "_ss.zip",
                                "_fg.zip",
                                "_fx.zip",
                                "_dd.zip"),
                         
                         Map=c("_station_tx.txt",
                               "_station_tn.txt",
                               "_station_tg.txt",
                               "_station_rr.txt",
                               "_station_pp.txt",
                               "_station_cc.txt",
                               "_station_hu.txt",
                               "_station_sd.txt",
                               "_station_ss.txt",
                               "_station_fg.txt",
                               "_station_fx.txt",
                               "_station_dd.txt"),
                         ID=c("TX",
                              "TN",
                              "TG",
                              "RR",
                              "PP",
                              "CC",
                              "HU",
                              "SD",
                              "SS",
                              "FG",
                              "FX",
                              "DD"))
  
  linkMap[,downloadDatLink:=paste0(baseLinkDat,blendStat,Link)]
  linkMap[,downloadStationLink:=paste0(baseLinkMap,blendStat,Map)]
  linkMap[,downloadDatPath:=paste0(currPath,"/",VarName)]
  
  return(linkMap)
  
}

DownloadData <- function(metVar,linkMap){
  library(data.table)
  cat("Currently preparing system to Download the desired meteorological data..\n")
  cat("Creating download local system paths...\n")
  ## Creating Download Local System Paths
  dir.create(linkMap[VarName==metVar,downloadDatPath], showWarnings = FALSE)
  file <- basename(linkMap[VarName==metVar,downloadDatLink])
  cat("Currently downloading data: ",metVar,"\n")
  downloadTime <- system.time(download.file(linkMap[VarName==metVar,downloadDatLink], 
                                            paste0(linkMap[VarName==metVar,downloadDatPath],"/",file)))
  cat("Data downloaded in: ",downloadTime[[3]]," secs\n") 
  cat("Decompressing downloaded files...\n")
  unzipTime <- system.time(unzip(paste0(linkMap[VarName==metVar,downloadDatPath],"/",file), exdir=linkMap[VarName==metVar,downloadDatPath]))
  cat("Files decompressed in ",unzipTime[[3]]," secs\n")
  # Delete Zip File
  unlink(paste0(linkMap[VarName==metVar,downloadDatPath],"/",list.files(linkMap[VarName==metVar,downloadDatPath], pattern=".zip")))
}

# Download Data in parallel
ParallelDownloadData <- function(core_id,mapFile, linkMap,DownloadData){
  library(data.table)
  library(foreach)
  library(doParallel)
  # Define meteorological variables adressing to core_id
  metVarList <- mapFile[Core==core_id,Index]
  
  # Download Data for each meterological variable
  for (metVarList_id in metVarList){
    DownloadData(metVarList_id, linkMap)
  }
}

# Convert Degrees,minutes,seconds to decimal degrees 
ConvertCoord <- function(x) {
  tempLoc <- str_split(x, pattern = ":")
  x.out  <- as.numeric(tempLoc[[1]][1]) + as.numeric(tempLoc[[1]][2])/60 + as.numeric(tempLoc[[1]][3])/3600
  return(x.out)
}


## Manipulate Mapping File - Keep Existing MEteorological Stations
ManipulateMapping <- function(metVar){
  # Find Data path of variable of interest
  tempDownloadPath <- linkMap[VarName %in% metVar,downloadDatPath]
  
  tempMapping <- data.table(read.table(paste0(tempDownloadPath,"/sources.txt"), skip = 22 ,sep=",",
                                       stringsAsFactors = FALSE, header=TRUE, quote=""))
  
  # Manipulate Longitude and Lattitude - Convert Degrees,minutes,seconds to decimal degrees 
  
  tempMapping[,latUpd:=round(sapply(LAT,ConvertCoord),5)][,longUpd:=round(sapply(LON,ConvertCoord),5)]
  tempMapping[,LatLong:=paste0(latUpd,":",longUpd)]
  tempMapping <- tempMapping[!duplicated(LatLong)] # get rid off stations with duplicated locations
  tempMapping[, START:= as.Date(as.character(START), format = "%Y%m%d")]
  tempMapping[, STOP:= as.Date(as.character(STOP), format = "%Y%m%d")]
  
  # Find Available Stations with their names and their location
  dataFileNames <- list.files(tempDownloadPath, pattern=".txt")
  dataFileNames <- dataFileNames[!dataFileNames %in% c("elements.txt", "sources.txt","stations.txt")]
  dataFileNamesIDs <- as.numeric(gsub(".txt","",gsub(paste0(linkMap[VarName==metVar,ID],"_SOUID"),"",dataFileNames)))
  availableStationsMap <- data.table(SOUID=as.integer(dataFileNamesIDs))
  tempMapping <- copy(tempMapping[,c("SOUID","SOUNAME","CN","latUpd","longUpd","LatLong","START", "STOP"), with=F])
  tempMapping <- copy(tempMapping[SOUID %in% availableStationsMap[,SOUID]])
  
  tempMapping[,MetVar:=metVar]
  return(tempMapping)
}

# Download data
ExecuteDownloadData <- function(process, config, currPath, numCores, linkMap, mapFile, ParallelDownloadData, DownloadData){
  
  if (process == TRUE){
    cl <- makeCluster(numCores)
    registerDoParallel(cl)
    foreach(core_id=1:numCores, .verbose = T, .packages=c("data.table")) %dopar% ParallelDownloadData(core_id, mapFile, linkMap, DownloadData)
    stopCluster(cl)
  }
  
}

CreateTablesScripts <- function(Index, ID, schemaID){
  
  scriptID <- paste0("CREATE TABLE ",schemaID,".",Index," (
                     STAID INTEGER,
                     SOUID INTEGER,
                     DATE INTEGER,
                     ",ID," INTEGER,
                     Q_",ID," INTEGER
  )
                     ")
  
  return(scriptID)
}


UploadFiles <- function(con, config, tableID, pathID, fileID){
  
  print(fileID)
  scriptID <- paste0("COPY  ",config[["default"]]["schema_name"],".",tolower(tableID)," FROM PROGRAM 'tail -n +21 ",paste0(pathID,"/",fileID),"'  DELIMITER ',';")
  dbSendQuery(con,scriptID)
  
}

ParallelUploadData <- function(config, coreID, uploadMapper, UploadFiles){
  
  library(RODBC)
  library(DBI)
  library(odbc)
  library(RPostgreSQL)
  library(data.table)
  
  drv <- dbDriver("PostgreSQL")
  con <- DBI::dbConnect(drv = drv,
                        dbname = "meteo_data",
                        user    = "konstantinos.mammas",
                        password    = "",
                        host = "localhost",
                        port = 5432)
  
  temp <- copy(uploadMapper[Core == coreID])
  temp[, list(list(UploadFiles(con, config, varname, downloaddatapath, fileID))), by =Counter]
  
}


