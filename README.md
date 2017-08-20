README
================
Kostas Mammas, Statistical Programmer <br> mail: <mammaskon@gmail.com> <br>

-   [Introduction](#introduction)
-   [User instructions](#user-instructions)

Introduction
============

**ECADownloader** is an `R` interface for downloading data from [www.ecad.eu](www.ecad.eu). Using the interface of the tool the user is able to download dynamically the daily records of the following environmmental variables and save it locally:

-   Daily Max Temerature
-   Daily Mean Temperature
-   Daily Mean Temperature
-   Daily Precipitation Amount
-   Daily Mean Sea Level Pressure
-   Daily Cloud Cover
-   Daily Humidity
-   Daily Snow Depth
-   Daily Sunshine Duration
-   Daily Mean Wind Speed
-   Daily Max Wind Gust
-   Daily Wind Direction

User instructions
=================

The following steps need to be followed:

1.  The user has to define the working directory
2.  Define number of cores. The number of cores should not exceed the number of the environmental variables
3.  Define the meteorological variables to download:

The following script downloads only the first 2 environmental variables; Daily Maximum Temperature & Dauliy Minimum Temperature.

``` r
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
```
