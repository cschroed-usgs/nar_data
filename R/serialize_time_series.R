BASE_PATH <- 'inst/extdata/'
EXTENSION <- '.csv'
write_out <- function(dataframe_name){
	dataframe <- get(dataframe_name)
	file_name <- paste(BASE_PATH, dataframe_name, EXTENSION, sep = "")
	write.csv(dataframe, file_name, quote = TRUE, na = "NULL")
	return(file_name);
}

#'@export
serialize_time_series <- function(){
	data_frame_names <- c(
		'discqw',
		'aloads',
		'mloads',
		'aflow',
		'mflow',
		'dflow'
	)
	lapply(data_frame_names, write_out)
}