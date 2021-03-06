library(testthat)
library(validate)
library(dplyr)
options(scipen=999)
context("may load")

temp_mloads <- mloads
temp_mloads$TONS_N<-as.numeric(temp_mloads$TONS)
temp_mloads$TONS_L95_N<-as.numeric(temp_mloads$TONS_L95)
temp_mloads$TONS_U95_N<-as.numeric(temp_mloads$TONS_U95)


temp_mloads_recent<-temp_mloads[temp_mloads$WY %in% max(temp_mloads$WY),] 

#length(unique(temp_mloads_recent$SITE_ABB))

#looking for more thorough explanation of the 'validate' library capabilities?
#Run:
# vignette("intro", package="validate")

test_that("may load has the correct columns", {
	expect_has_names(mloads, c(
		"SITE_ABB",
		"SITE_FLOW_ID",
		"SITE_QW_ID",
		"CONSTIT",
		"WY",
		"MODTYPE",
		"TONS",
		"TONS_L95",
		"TONS_U95"
	))
})

test_that("may load's columns are correctly typed", {
	result <- validate::check_that(mloads,
		is.integer(c(WY, MONTH)),
		is.character(c(
			SITE_ABB,
			SITE_QW_ID,
			SITE_FLOW_ID,TONS, TONS_L95, TONS_U95
		)),
		is.factor(CONSTIT),
		is.factor(MODTYPE)
	)
	expect_no_errors(result)
})

test_that("may load has a reasonable range of values", {
	result <- validate::check_that(temp_mloads, 
		TONS_N > 0,
		TONS_N < 5E8,
		TONS_L95_N < TONS_U95_N,
		TONS_L95_N < TONS_N,
		TONS_N < TONS_U95_N,
		nchar(SITE_ABB) == 4,
		WY < 2020,
		WY > 1950
	)
	expect_no_errors(result)
})

test_that("may loads for the MISS site are included for multiple years", {
	miss_sites <- subset(mloads, SITE_ABB == 'MISS')
	YEAR_OF_FIRST_MISS_LOADS = 1993
	num_years = max(mloads['WY']) - YEAR_OF_FIRST_MISS_LOADS
	expect_gte(nrow(miss_sites), num_years) #this is a conservative lower bound -- there are likely  multiple entries for each constituent for each year
})

test_that("may loads are less than corresponding annual loads for a given site/water year/constituent", {
  tt<-left_join(temp_mloads, aloads, by = c("SITE_ABB" = "SITE_ABB", "WY" = "WY","CONSTIT"="CONSTIT"))
  tt<-tt[!is.na(tt$TONS.y),]
  
  result <- validate::check_that(tt, 
                                 TONS_N < as.numeric(TONS.y)
                             
                                 
                                 )
  expect_no_errors(result)
})



test_that("Most recent water year has all of the necessary sites ", {

  expected <- sort(c("HAZL","PADU","GRAN","CLIN","WAPE","KEOS","VALL","GRAF","SIDN","OMAH","ELKH","LOUI","DESO","HERM","THEB","SEDG","HARR","KERS","BELL","MORG",
                                                                  "STFR","MELV","VICK","SUMN","STTH","GULF","NEWH","CANN","MISS","HAST","LITT"))
  actual <- sort(unique(temp_mloads_recent$SITE_ABB))
  expect_equal(actual, expected)
  
})


test_that("Load data have the correct number of significant digits", {
  result <- validate::check_that(temp_mloads, 
                                 
                                 count_sig_figs(temp_mloads$TONS_N/1E5) <= 3,
                                 count_sig_figs(temp_mloads$TONS_L95_N/1E5) <= 3,
                                 count_sig_figs(temp_mloads$TONS_U95_N/1E5) <= 3
                                 
                                 )
  
  expect_no_errors(result)
})


test_that("There are no duplicate values", {
  mloads_without_ignored_modtypes <- subset(temp_mloads, !(MODTYPE %in% c('COMP', 'CONTIN')))
  unique_columns <- mloads_without_ignored_modtypes[c('SITE_QW_ID', 'CONSTIT', 'WY')]
  expect_no_duplicates(unique_columns)
  
})

