library(testthat)
library(nardata)
context("serialization")

test_that("serialization is current", {
	old_wd <- getwd()
	#presume that user has not changed the name of the clone dir from the default
	default_clone_dir <- 'nar_data'
	warning(' initial working directory: ', old_wd)
	tryCatch({
		#linux or OSX
		dir_sep <- '/'
		if (.Platform$OS.type == 'windows') {
			dir_sep <- '\\'
		}
		
		relative_path_to_repo_root <- paste(rep('..', 2), collapse = dir_sep)
		
		#check to see if running from a "<packageName>.Rcheck" subdir outside the repo
		clone_dir_index <- regexpr(default_clone_dir, getwd())[1]
		
		
		if ( -1 == clone_dir_index) {
			#if couldn't find clone dir in path
			rcheck_path_is_subdir_of_clone_dir <- FALSE
		} else {
			#if could find clone dir in path, make sure that it is before the .Rcheck dir
			rcheck_path_index <- regexpr('nardata\\.Rcheck', getwd())[1]
			rcheck_path_is_subdir_of_clone_dir <- rcheck_path_index > clone_dir_index
		}
		
		if (!rcheck_path_is_subdir_of_clone_dir) {
			#try to navigate back to the repo
			relative_path_to_repo_root <- paste(relative_path_to_repo_root, 'nar_data', sep = dir_sep)
		}
		
		if (!dir.exists(relative_path_to_repo_root)) {
			stop("ERROR: could not determine path to git repo root. working dir is: ",
				 old_wd, " tried to use non-existent relative path: ",
				 relative_path_to_repo_root
			)
		} else {
			warning("relative path to repo root exists: ", relative_path_to_repo_root)
			setwd(relative_path_to_repo_root)
	
			nardata::serialize_time_series()
			path_to_data_dir_from_repo_root <- nardata::get_serialized_data_dir()
			warning('path_to_data_dir_from_repo_root: ', path_to_data_dir_from_repo_root)
			git_command <- paste('git ls-files -mo', path_to_data_dir_from_repo_root)
			warning('git command: ', git_command)
			stale_or_new_files <- system( git_command, intern = TRUE)
			
			if (0 != length(stale_or_new_files)) {
				stale_or_new_files <- paste(stale_or_new_files, collapse = ', ')
				warning('stale or new files: ', stale_or_new_files)
				testthat::fail(paste("The following serialized files are not current:", stale_or_new_files, 'Try running nardata::serialize_time_series(), and adding and committing the resulting files.'))
			} else {
				testthat::succeed("Serialized files are not checked")
			}
		}
	}, finally = {
		setwd(old_wd)
	})
})
