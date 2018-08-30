availableDBSchemas <- function(){ return("SELECT * FROM INFORMATION_SCHEMA.SCHEMATA") }

DropSchema <- function(schemaID){ return(paste0("DROP SCHEMA ",schemaID," CASCADE")) }
CreateSchema <- function(schemaID){ return(paste0("CREATE SCHEMA ",schemaID)) }

dbConncetor <- function(dbType, dbNameID, hostID, portID, usernameID, passwordID){
  
  # name  : dbConncetor
  # inputs:
  #       dbNameID: database name
  #         dtype : databse type (i.e. postgresql, impala, mysql)
  #         hostID: databse host (i.e. localhost)
  #         portID: database port
  #     usernameID: database username 
  #     passwordID: database password
  
  # outputs:
  #           conn: connection object
  
  if (dbType == "postgresql"){
    
    library(RPostgreSQL)
    
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, 
                     dbname = dbNameID,
                     host = hostID,
                     port = portID,
                     user = usernameID,
                     password = passwordID)
    return(con)
  }
  
}

sqlExecutor <- function(targetDBType, sqlScript, conn){
  
  # name  : sqlExecutor
  # inputs:
  #         dtype : databse type (i.e. postgresql, impala, mysql)
  
  # outputs:
  #       statusID: provide a flag with the status update
  
  # Perform Translation
  sqlScript <- translateSql(sql          = sqlScript,
                            targetDialect = targetDBType
  )[["sql"]]
  
  # Execute Scirpt
  statusID <- dbGetQuery(conn, sqlScript)
  
  return(statusID)
}

prepareDB <- function(config, linkMap, dropSchema, createSchema, createEmptyTbl){
  
  if (dropSchema == TRUE){
    cat("Currently dropping the database schema...\n")
    # Drop Schema
    sqlExecutor(targetDBType = "postgresql",
                sqlScript    = DropSchema(config[["default"]][["schema_name"]]),
                conn         = conn
    )
  }
  if (createSchema == TRUE){
    cat("Creating new Schema\n")
    # Create Schema
    sqlExecutor(targetDBType = "postgresql",
                sqlScript    = CreateSchema(config[["default"]][["schema_name"]]),
                conn         = conn
    )
  }
  if (createEmptyTbl == TRUE){ 
    cat("Generating scripts and creating empty tables\n")
    # Create Tables Scripts
    linkMap[, create_table_script:= CreateTablesScripts(Index    = VarName,
                                                        ID       = ID,
                                                        schemaID = config[["default"]][["schema_name"]]
    ),
    by = 1:nrow(linkMap)
    ]
    
    # Execute Scripts of creating tables with records
    linkMap[VarName %in% mapFile[,Index]][, sqlExecutor(targetDBType = "postgresql",
                                                        sqlScript    = create_table_script,
                                                        conn         = conn
    ),
    by = 1:nrow(linkMap[VarName %in% mapFile[,Index]])
    ]
  }
  
  return(linkMap)
}

