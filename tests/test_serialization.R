library(testthat)
library(nardata)
context("serialization")

test_that("serialization is current", {
	
	old_wd <- getwd()
	warning(' initial working directory: ', old_wd)
	tryCatch({
		#linux or OSX
		dir_sep <- '/'
		if (.Platform$OS.type == 'windows') {
			dir_sep <- '\\'
		}
		relative_path_to_repo_root <- paste(rep('..', 2), collapse = dir_sep)
		relative_path_to_repo_root <- paste(relative_path_to_repo_root, 'nar_data', sep = dir_sep)
		warning('going to attempt to set wd to : ', relative_path_to_repo_root)
		setwd(relative_path_to_repo_root)
		nardata::serialize_time_series()
		path_to_data_dir_from_repo_root <- nardata::get_serialized_data_dir()
		warning('path_to_data_dir_from_repo_root: ', path_path_to_data_dir_from_repo_root)
		git_command <- paste('git ls-files -mo', path_to_data_dir_from_repo_root)
		warning('git command: ', git_command)
		stale_or_new_files <- system( git_command, intern = TRUE)
		
		if (0 != length(stale_or_new_files)) {
			stale_or_new_files <- paste(stale_or_new_files, collapse = ', ')
			warning('stale or new files: ', stale_or_new_files)
			testthat::fail(paste("The following serialized files are not current. Try running nardata::serialize_time_series(), and adding and committing the resulting files.:", stale_or_new_files))
		} else {
			testthat::succeed("Serialized files are not checked")
		}
	}, finally = {
		setwd(old_wd)
	})
})
