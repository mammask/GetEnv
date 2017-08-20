
# ----------------------------------------------------------------------------#
# Download Open Environmental Data v1a                                        #
#      author: Konstantinos Mammas                                            #
#     contact: mammas_k@live.com                                              #
# script name: downloadLink_v1a.R                                             #
#        info: aims to download environmental data from:                      #
#              http://www.ecad.eu/dailydata/predefinedseries.php for          #
#              reporting and analytic reasons.                                #
# ----------------------------------------------------------------------------#

# Meteorological Variables List ----------------------------------------------#
#
# DailyMaxTemp:         Daily Max Temerature                                  #
# DailyMinTemp:         Daily Mean Temperature                                #
# DailyMeanTemp:        Daily Mean Temperature                                #
# DailyPrecipAmount:    Daily Precipitation Amount                            #
# DailyMeanSeaLVLPress: Daily Mean Sea Level Pressure                         #
# DailyCloudCover:      Daily Cloud Cover                                     #
# DailyHumid:           Daily Humidity                                        #
# DailySnowDepth        Daily Snow Depth                                      #
# DailySunShineDur      Daily Sunshine Duration                               #
# DailyMeanWindSpeed    Daily Mean Wind Speed                                 #
# DailyMaxWindGust      Daily Max Wind Gust                                   #
# DailyWindDirection    Daily Wind Direction                                  #
#
# ----------------------------------------------------------------------------#
## Define working directory
currPath <- "~/Documents/ECADownloader/code/"
setwd(currPath)
## Load Important libraries 

library(stringr)
library(ggmap)
library(RPostgreSQL)
library(googleVis)
library(tcltk)
library(data.table)
library(foreach)
library(doParallel)

# ----------------------------------------------------------------------------#
# Define number of cores that will be used in the following steps
NumCores <- 6
blended <- TRUE  ## Define if dataset will be blended or nonblended
# ----------------------------------------------------------------------------#

## Define current working directory - Load Supporting Functions
source("./externalFunctions_v1a.R")
# ----------------------------------------------------------------------------#

## Define meteorological variables to download
metVar <- data.table(metVar = c("DailyMaxTemp", "DailyMinTemp",
                                "DailyMeanTemp", "DailyPrecipAmount",
                                "DailyMeanSeaLVLPress","DailyCloudCover",
                                "DailyHumid", "DailySnowDepth", 
                                "DailySunShineDur","DailyMeanWindSpeed",
                                "DailyMaxWindGust","DailyWindDirection"),
                     Include = c("yes",
                                 "yes",
                                 "no",
                                 "no",
                                 "no",
                                 "no",
                                 "no",
                                 "no",
                                 "no",
                                 "no",
                                 "no",
                                 "no"))

metVar <- metVar[Include=="yes", metVar]
# ----------------------------------------------------------------------------#

## Create Distribution Map
distrMap <- data.table(Variable=metVar)
splits <-  ceiling(nrow(distrMap)/min(c(NumCores,length(metVar))))
distrMap[,Core:=rep(1:NumCores, each=splits)[1:nrow(distrMap)]]
cat("Approximately each core is responsible for downloading",splits,"datasets")
## Download Selected Meteorological Indices in Paralllel
cl <- makeCluster(NumCores)
registerDoParallel(cl)
foreach(core_id=1:NumCores, .verbose = T) %dopar% parallelDownloadData(core_id)
stopCluster(cl)

# ----------------------------------------------------------------------------#
# Manipualte Mapping Files
mappingTotal <- list()
totalMap <- lapply(metVar,manipulateMapping)
totalMap <- rbindlist(totalMap)
