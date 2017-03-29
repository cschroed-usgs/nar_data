#' Generate code from data frames
#' This is not part of the data pipeline, but used to more quickly create
#' code that is used on the service-side of the application.  If columns
#' change in the data frames or new data frames are added this can be
#' run to update the code.
#' 
#' This function will place several files in the BASE_PATH.
#'
#'@importFrom R.utils toCamelCase
#'@export
library(R.utils)
generate_code <- function(){
  lapply(get_time_series_data_frame_names(), write_out_ddl)
  lapply(get_time_series_data_frame_names(), write_out_liquibase)
  lapply(get_time_series_data_frame_names(), write_out_mapper)
  lapply(get_time_series_data_frame_names(), write_out_java)
}

write_out_ddl <- function(dataframe_name){
  dataframe <- get(dataframe_name)
  file_name <- paste0(BASE_PATH, dataframe_name, '.sql')
  sink(file=file_name)
  ddl_prequel(dataframe_name)
  ddl(dataframe)
  ddl_sequel(dataframe_name)
  sink()
  return(file_name)
}

write_out_liquibase <- function(dataframe_name){
  dataframe <- get(dataframe_name)
  file_name <- paste0(BASE_PATH, dataframe_name, '.xml')
  sink(file=file_name)
  liquibase(dataframe, dataframe_name)
  sink()
  return(file_name)
}

write_out_mapper <- function(dataframe_name){
  dataframe <- get(dataframe_name)
  file_name <- paste0(BASE_PATH, dataframe_name, 'Mapper.xml')
  sink(file=file_name)
  mapresults(dataframe)
  columns(dataframe)
  sink()
  return(file_name)
}

write_out_java <- function(dataframe_name) {
  dataframe <- get(dataframe_name)
  file_name <- paste0(BASE_PATH, dataframe_name, ".java")
  sink(file=file_name)
  javadeclaration(dataframe)
  sink()
  return(file_name)
}

ddl_prequel <- function(dataframe_name){
  cat(paste0('--changeset ', Sys.getenv("USERNAME"),':add_', dataframe_name))
  cat(paste0('\nDROP TABLE ', dataframe_name, ';\n'))
  cat(paste('\nCREATE TABLE', dataframe_name))
  cat('\n(\n')
}

NUMERIC_SIZE <- "22,11"

ddl <- function(df) {
  names <- colnames(df)
  cat('  id serial NOT NULL,\n')
  for (i in 1:ncol(df)) {
    type <- sqltype(df[[i]])
    cat(paste0('  ', tolower(names[i]), ' ', type))
    if(type == 'numeric') {
      cat(paste0('(', NUMERIC_SIZE, ')'))
    }
    if(i != ncol(df)) {
      cat(',')
    }
    cat('\n')
  }
}

ddl_sequel <- function(dataframe_name) {
  cat('\n);\n')
  cat(paste0('--rollback DROP TABLE ', dataframe_name, ';\n\n'))
}

#' Writes out liquibase changesets for loading data into a table from csv.
#' Example output for a dataframe named 'aflow':
#' 
#' <delete tableName="aflow" />
#' <sql dbms="postgresql">
#'  COPY aflow(
#'    site_abb,
#'    site_qw_id,
#'    site_flow_id,
#'    wy,
#'    flow
#' ) FROM '${nar.data.location}/aflow.csv' DELIMITER ',' CSV HEADER NULL 'NULL';
#' </sql>
#' <rollback>delete from aflow</rollback>
liquibase <- function(df, dataframe_name) {
  table_name <- tolower(dataframe_name)
  names <- colnames(df)
  cat(paste0(
    '\t\t<delete tableName="', table_name, '" />\n',
    '\t\t<sql dbms="postgresql">\n',
      '\t\t\tCOPY ', table_name, '(\n'
    )
  )
  
  for (i in 1:ncol(df)) {
    cat('\t\t\t\t')
    cat(tolower(names[i]))
    if(i != ncol(df)){
      cat(',\n')
    }
  }
  
  cat(paste0(
    "\n\t\t\t) FROM '${nar.data.location}/", table_name, ".csv' DELIMITER ',' CSV HEADER NULL 'NULL';\n",
    '\t\t</sql>\n'
  ))
  cat(paste0(
    '\t\t<rollback>delete from ', table_name, '</rollback>\n'
  ))
}

mapresults <- function(df) {
  names <- colnames(df)
  for (i in 1:ncol(df)) {
    column <- paste0('\t\t<result property="', javaname(names[i]), '" ')
    column <- paste0(column, 'column="', tolower(names[i]), '" />\n')
    cat(column)
  }
}

columns <- function(df) {
  names <- colnames(df)
  for (i in 1:ncol(df)) {
    column <- paste0('\t\t', tolower(names[i]))
    if(i != ncol(df)) {
      column <- paste0(column, ',')
    }
    column <- paste0(column, '\n')
    cat(column)
  }
}

javadeclaration <- function(df) {
  names <- colnames(df)
  for (i in 1:ncol(df)) {
    type <- javatype(df[[i]])
    column <- paste0('\tprivate ', type, ' ', javaname(names[i]), ';\n')
    cat(column)
  }
}

sqltype <- function(column) {
  switch(class(column),
    character="text",
    numeric="numeric",
    integer="integer",
    factor="text",
    Date="date"
  )
}

liquibasetype <- function(column) {
  switch(class(column),
    character="STRING",
    numeric="NUMERIC",
    integer="NUMERIC",
    factor="STRING",
    Date="DATE"
  )
}

javatype <- function(column) {
  switch(class(column),
    character="String",
    numeric="double",
    integer="int",
    factor="String",
    Date="Date"
  )
}

javaname <- function(name) {
  return(toCamelCase(tolower(name), split="_"))
}