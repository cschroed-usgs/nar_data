EXTENSION <- '.csv'
write_out <- function(dataframe_name){
	dataframe <- get(dataframe_name)
	file_name <- paste(get_serialized_data_dir(), dataframe_name, EXTENSION, sep = "")
	write.csv(dataframe, file_name, quote = TRUE, na = "NULL")
	return(file_name);
}

#' @export
get_serialized_data_dir <- function(){
	dir_sep <- '/'
	if (.Platform$OS.type == 'windows') {
		dir_sep <- '\\'
	}
	serialized_data_dir <- paste('inst', 'extdata', sep = dir_sep)
	#append a trailing slash
	serialized_data_dir <- paste(serialized_data_dir, dir_sep, sep = '')
	
	return(serialized_data_dir)
}

#' @export
serialize_time_series <- function(){
	serialized_data_dir <- get_serialized_data_dir()
	if (!dir.exists(serialized_data_dir)) {
		stop(paste(
			'The function "serialize_time_series" must be run with the git',
			'repository as your working directory. Current working directory is:',
			getwd())
		 )
	} else {
		data_frame_names <- c(
			'discqw',
			'aloads',
			'mloads',
			'aflow',
			'mflow',
			'dflow'
		)
		return(lapply(data_frame_names, write_out))
	}
}