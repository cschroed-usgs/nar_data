#' @title Serialize time series 
#' @description Provides numerous functions to serialize all time series

BASE_PATH <- 'inst/extdata/'
EXTENSION <- '.csv'

# Some large data frames need to be serialized into multiple CSVs because liquibase does not handle
# large CSVs well. For every data frame that needs to be split, we define a list whose keys are data frame
# names and whose values are the number of files the data frame should be split across. We do not add data frames
# to this list if they do not need to be split across multiple files. In other words, we should never see a list entry
# with the value of 1.
#
# IF YOU MODIFY THIS LIST, THEN YOU MUST ALSO UPDATE THE LIQUIBASE SCRIPTS.
# IF YOU DO NOT, THEN YOU RISK OMITTING DATA.
# 
# The following scenarios use a variable 'N' to refer to the number of CSV files that a data frame is split across.
#
# If you add an entry to this list, then you need to add 'N' loadData changesets to the liquibase scripts.
# If you remove an entry from this list, then you need to remove 'N' loadData changesets from the liquibase scripts,
# If you modify the key (data frame name) of an entry in this list, then you need to rename the corresponding 'N' loadData liquibase changesets.
# If you modify the value (file count) of an entry in this list, then you will need to adjust the number of loadData changesets to correspond 
# to the new value of 'N'.
# 
# If you add 'aloads' or 'mloads' to this list, you will need to adjust the scripts for 
# generating river width line charts, pie charts, and moving averages in the nar-services-data repo.

data_frame_name_to_file_count = list(
  'pestsamp' = 2
)

#' Writes a dataframe to csv
#'
#' @param dataframe_name the character name of a data frame
#' @param dataframe the data.frame itself
#' @param base_path the character path to a directory with trailing slash
#' @param extension the character suffix for the serialized data frame
#' @return the name of the file
write_out <- function(dataframe_name, dataframe, base_path, extension){
  page_number <- 0
  row_offset <- 0
  row_step <- 1.25e6
  max_page_number <- ceiling(nrow(dataframe)/row_step)
  file_names = c()
  while(page_number < max_page_number) {
    limit <- min(row_offset + row_step, nrow(dataframe))
    page <- dataframe[row_offset:limit,]
    
    file_name <- write_out_page(page_number, dataframe_name, page, base_path, extension)
    file_names <- c(file_names, file_name)
    
    page_number <- page_number + 1
    row_offset <- limit
  }

	return(file_names);
}

#' Writes a dataframe to csv
#' @param page_number the 
#' @param dataframe_name the character name of a data frame
#' @param page the subset of the data.frame itself
#' @param base_path the character path to a directory with trailing slash
#' @param extension the character suffix for the serialized data frame
#' @return the name of the file
write_out_page <- function(page_number, dataframe_name, page, base_path, extension){
  if(page_number == 0) {
      page_number = ''
  }
  file_name <- paste(base_path, dataframe_name, page_number, extension, sep = "")
  write.csv(page, file_name, quote = TRUE, na = "NULL")
  
  return(file_name);
}

#' Get all data frame names
#'
#' @return a list of string data frame names
#' @export
get_time_series_data_frame_names <- function(){
	return(list(
		'aflow',
		'aloads',
		'dflow',
		'discqw',
		'mflow',
		'mloads',
		'pest21day',
		'pest60day',
		'pestsamp',
		'pestsites',
		'pestweightave'
	))
}

#' Get all data frames and their names
#'
#' @return a list whose keys are strings and whose values are the data frames
#' @export
get_time_series_data_frames_and_names <- function() {
	all_time_series <- list()
	for (time_series_name in get_time_series_data_frame_names()) {
		all_time_series[[time_series_name]] <- get(time_series_name)
	}
	return(all_time_series)
}

#' Execute a function on each named data frame
#'
#' given a list of dataframe names mapped to data frames, iterate
#' through every one, passing the dataframe name and dataframe to
#' the specified function. The specified function must accept two
#' parameters. The first is a character name. The second is a 
#' data frame.
#' @param data_frames a vector of data.frames
#' @param fn a function that will be passed a name and a data frame
#' @export
for_each_data_frame <- function(data_frames, fn) {
	for (data_frame_name in names(data_frames)) {
		data_frame <- data_frames[[data_frame_name]]
		fn(data_frame_name, data_frame)
	}
}

#' Serializes time series with default options
#' 
#' This is called to execute the default behavior on Job Servers. Tests and customizations should use
#' serialize_specific_time_series
#' @export
serialize_time_series <- function(){
	return(serialize_specific_time_series(get_time_series_data_frames_and_names(), BASE_PATH, EXTENSION))
}

#' Serialize the specified time series
#' 
#' Serializes the specified time series to csv at the given base path with the given file extension.
#' file names in the destination dir are the concatenation of the data frame's name, a dot, and the extension
#' This function briefly modifies the global scipen option. It restores the previous value after it has
#' accomplished its main tasks.
#' 
#' @param time_series_data_frames_and_names a list whose keys are strings and whose values are data frames
#' @param base_path a string path to the directory where data frames should be serialized. Must include trailing slash.
#' @param extension a string file extension
#' @return vector of character file names
#' @export
serialize_specific_time_series <- function(time_series_data_frames_and_names, base_path, extension){
	old_scipen_value <- options()$scipen
	all_files_written <- c()
		tryCatch({
		options(scipen = 999)
		for_each_data_frame(time_series_data_frames_and_names, function(data_frame_name, data_frame){
			written_files <- write_out(data_frame_name, data_frame, base_path, extension)
			actual_file_count <- length(written_files) 
			validate_that_data_frame_was_split_into_correct_number_of_files(data_frame_name, actual_file_count)
			all_files_written <- c(all_files_written, written_files)
		})
	}, 
	finally = {
		options(scipen = old_scipen_value)
	})
	return(all_files_written)
}

mutli_file_error_message <- paste("Please review the documentation for the data_frame_name_to_file_count variable in serialize_time_series.R so",
                                  "that you can appropriately update the registry of multi-file data frames and modify the liquibase scripts accordingly.")

#validate that large data frames are being split into the expected number of files
validate_that_data_frame_was_split_into_correct_number_of_files <- function(data_frame_name, actual_file_count) {
    if(data_frame_name %in% names(data_frame_name_to_file_count)) {
      expected_file_count <- data_frame_name_to_file_count[[data_frame_name]]
      if(expected_file_count != actual_file_count) {
        stop(
          "Data frame ",
          data_frame_name,
          " is registered as being split across ",
          expected_file_count,
          " files, but it was split across ",
          actual_file_count,
          " files instead. ",
          mutli_file_error_message
        )
      }
    } else if (actual_file_count > 1){
      stop(
        "Data frame ",
        data_frame_name,
        " is not registered as a data frame that must be split across multiple files, yet it exceeds the row limit for a single file. ",
        mutli_file_error_message
      )
    }

}

get_unique_sites_from_data_frame <- function(frame){
  unique(frame$SITE_QW_ID)
}

concatenate_unique_site_ids <- function(allIds, idsFromThisFrame){
  unique(c(idsFromThisFrame, allIds))
}

has_site_id_column <- function(frame){
  "SITE_QW_ID" %in% names(frame)
}

#' Given a list of data frames, get a list of all unique site ids.
#' Silenty ignores any data frames that do not have the expected site id column name
#' @param data_frames a list of data frames
#' @return vector of unique character site ids
#' @export
get_site_ids <- function(data_frames){
  data_frames_with_site_id_columns <- Filter(
    has_site_id_column,
    data_frames
  )
  
  sites_from_each_data_frame <- Map(
    get_unique_sites_from_data_frame,
    data_frames_with_site_id_columns
  )
  
  unique_sites <- Reduce(
    concatenate_unique_site_ids, 
    sites_from_each_data_frame,
    c()
  )
  
  return(unique_sites)
}

#' Get a list of all unique site ids across all the time series data frames
#' @return vector of unique character site ids
#' @export
get_all_site_ids <- function(){
  get_site_ids(get_time_series_data_frames_and_names())
}
