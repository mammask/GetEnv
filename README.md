GetEnvTS - Download Environmental Time-Series Data
<img src="https://github.com/mammask/GetEnv/blob/master/img/get-env.png" height="192px"/>
================
Kostas Mammas, Data Scientist <br> mail: <mammaskon@gmail.com> <br>

Introduction
============

**GetEnvTS** is an `R` interface for downloading data from [www.ecad.eu](www.ecad.eu). Using the interface of the tool the user is able to download dynamically the daily records of a set of environmmental variables and save them locally on a relational database model.

All the parameterizations of the tool are made through the config.yml file. The package is integrated with a postgresql database. The following parameters can be adjusted:

```yaml
# Default Parameters
default:
  operating_system: "WINDOWS"    # Operating system (LINUX, MACOS, WINDOWS)
  num_cores:      4              # Number of cores
  blended:        FALSE          # Blended or non blended series
  schema_name:    "tran_ler"     # Name of database schema
  drop_schema:    TRUE           # Drop old schema
  create_schema:  TRUE           # Create new schema
  download_data:  TRUE           # Download data
  create_empty_tables: TRUE      # Create empty meteorological tables

# Available Meteorological Indices
indices:
  DailyMaxTemp:         FALSE
  DailyMinTemp:         FALSE
  DailyMeanTemp:        FALSE      
  DailyPrecipAmount:    TRUE  
  DailyMeanSeaLVLPress: FALSE
  DailyCloudCover:      FALSE
  DailyHumid:           TRUE
  DailySnowDepth:       FALSE
  DailySunShineDur:     FALSE
  DailyMeanWindSpeed:   FALSE
  DailyMaxWindGust:     FALSE
  DailyWindDirection:   TRUE

# Required packages; if not installed already then automatic installation will be performed
packages: ["data.table", "shiny", "shinythemes", "DT",
           "plotly", "RPostgreSQL", "dygraphs", "stringr",
           "shiny", "shinydashboard", "RColorBrewer", "plotly",
           "reshape2","yaml","markdown","rmarkdown", "gsubfn",
           "tableHTML", "SqlRender", "htmltools","config", 
           "foreach", "doParallel", "DBI", "RODBC"
          ]

# Database configuaratopns
database_config:
  type:          "postgresql"
  username:      "username"
  password:      "password"
  database_name: "meteo_data"
  localhost:     "localhost"
  from_sql:      "postgresql"
  to_sql:        "postgresql"
  port:          5432
```

Running GetEnv
============

In command line, set the current path to the path of the code folder and run ```Rscript main.R```:

![](https://github.com/mammask/GetEnv/blob/master/img/screenshot2.gif?raw=true)
