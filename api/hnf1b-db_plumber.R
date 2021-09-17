# hnf1b-db_plumber.R
## to do: adapt "serializer json list(na="null")"

##-------------------------------------------------------------------##
# load libraries
library(plumber)
library(tidyverse)
library(DBI)
library(RMariaDB)
library(jsonlite)
library(config)
library(jose)
library(plotly)
library(RCurl)
library(stringdist)
library(xlsx)
library(easyPubMed)
library(rvest)
library(lubridate)
library(pool)
library(memoise)
library(coop)
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
dw <- config::get("hnf1b_db_local")
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
pool <- dbPool(
  drv = RMariaDB::MariaDB(),
  dbname = dw$dbname,
  host = dw$host,
  user = dw$user,
  password = dw$password,
  server = dw$server,
  port = dw$port
)
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## global variables

##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
##-------------------------------------------------------------------##
# Define global functions


##-------------------------------------------------------------------##
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
##-------------------------------------------------------------------##
#* @apiTitle HNF1B-db API

#* @apiDescription This is the API powering the HNF1B-db website and allowing programmatic access to the database contents.
#* @apiVersion 0.1.0
#* @apiTOS http://www.hnf1b.org/terms/
#* @apiContact list(name = "API Support", url = "http://www.hnf1b.org/support", email = "support@hnf1b.org")
#* @apiLicense list(name = "CC BY 4.0", url = "https://creativecommons.org/licenses/by/4.0/")

#* @apiTag report Report related endpoints
#* @apiTag individual Individual related endpoints
#* @apiTag publication Publication related endpoints
#* @apiTag variant Variant related endpoints
##-------------------------------------------------------------------##
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## filters

#* @filter cors
## enable cross origin requests
## based on https://github.com/rstudio/plumber/issues/66
function(req, res) {
  
	res$setHeader("Access-Control-Allow-Origin", "*")
  
	if (req$REQUEST_METHOD == "OPTIONS") {
		res$setHeader("Access-Control-Allow-Methods","*")
		res$setHeader("Access-Control-Allow-Headers", req$HTTP_ACCESS_CONTROL_REQUEST_HEADERS)
		res$status <- 200 
		return(list())
	} else {
		plumber::forward()
	}
}

##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Report endpoints

#* @tag report
## get all reports
#* @serializer json list(na="string")
#' @get /api/reports
function(res, sort = "report_id", `page[after]` = 0, `page[size]` = "all") {

	# get number of rows in report_view
	hnf1b_db_report_rows <- (pool %>% 
		tbl("report_view") %>%
		summarise(n = n()) %>%
		collect()
		)$n

	# split the sort input by comma and check if report_ids in the resulting list, if not append to the list for unique sorting
	sort_list <- str_split(str_squish(sort), ",")[[1]]
	
	if ( !("report_id" %in% sort) ){
		sort_list <- append(sort, "report_id")
	}

	# check if `page[size]` is either "all" or a valid integer and convert or assign values accordingly
	if ( `page[size]` == "all" ){
		page_after <- 0
		page_size <- hnf1b_db_report_rows
		page_count <- ceiling(hnf1b_db_report_rows/page_size)
	} else if ( is.numeric(as.integer(`page[size]`)) )
	{
		page_after <- as.integer(`page[after]`)
		page_size <- as.integer(`page[size]`)
		page_count <- ceiling(hnf1b_db_report_rows/page_size)
	} else
	{
		res$status <- 400 #Bad Request
		return(list(error="Invalid Parameter Value Error."))
	}

	# get data from database
	hnf1b_db_report_table <- pool %>% 
		tbl("report_view") %>%
		arrange(!!!syms(sort_list)) %>%
		collect()

	# find the current row of the requested page_after entry
	page_after_row <- (hnf1b_db_report_table %>%
		mutate(row = row_number()) %>%
		filter(report_id == page_after)
		)$row

	if ( length(page_after_row) == 0 ){
		page_after_row <- 0
		page_after_row_next <- ( hnf1b_db_report_table %>%
			filter(row_number() == page_after_row + page_size + 1) )$report_id
	} else {
		page_after_row_next <- ( hnf1b_db_report_table %>%
			filter(row_number() == page_after_row + page_size) )$report_id
	}

	# find next and prev item row
	page_after_row_prev <- ( hnf1b_db_report_table %>%
		filter(row_number() == page_after_row - page_size) )$report_id
	page_after_row_last <- ( hnf1b_db_report_table %>%
		filter(row_number() ==  page_size * (page_count - 1) ) )$report_id
		
	# filter by row
	hnf1b_db_report_collected <- hnf1b_db_report_table %>%
		filter(row_number() > page_after_row & row_number() <= page_after_row + page_size)

	# generate links for self, next and prev pages
	self <- paste0("http://", dw$host, ":", dw$port_self, "/api/reports/?sort=", sort, "&page[after]=", `page[after]`, "&page[size]=", `page[size]`)
	if ( length(page_after_row_prev) == 0 ){
		prev <- "null"
	} else
	{
		prev <- paste0("http://", dw$host, ":", dw$port_self, "/api/reports?sort=", sort, "&page[after]=", page_after_row_prev, "&page[size]=", `page[size]`)
	}
	
	if ( length(page_after_row_next) == 0 ){
		`next` <- "null"
	} else
	{
		`next` <- paste0("http://", dw$host, ":", dw$port_self, "/api/reports?sort=", sort, "&page[after]=", page_after_row_next, "&page[size]=", `page[size]`)
	}
	
	if ( length(page_after_row_last) == 0 ){
		last <- "null"
	} else
	{
		last <- paste0("http://", dw$host, ":", dw$port_self, "/api/reports?sort=", sort, "&page[after]=", page_after_row_last, "&page[size]=", `page[size]`)
	}

	links <- as_tibble(list("prev" = prev, "self" = self, "next" = `next`, "last" = last))

	# 
	list(links = links, data = hnf1b_db_report_collected)
}

#* @tag report
## get infos for a single report by report_id
#* @serializer json list(na="string")
#' @get /api/report/<report_id>
function(report_id) {

	report <- as.integer(URLdecode(report_id))

	# get data from database and filter
	report_collected <- pool %>% 
		tbl("report_view") %>%
		filter(report_id == report) %>%
		arrange(report_id) %>%
		collect()
}

## Report endpoints
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Individual endpoints


## Individual endpoints
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Variant endpoints

#* @tag variant
## get all variants
#* @serializer json list(na="string")
#' @get /api/variants
function(res, sort = "variant_id", `page[after]` = 0, `page[size]` = "all") {

	# get number of rows in report_variant_view
	hnf1b_db_variant_rows <- (pool %>% 
		tbl("report_variant_view") %>%
		summarise(n = n()) %>%
		collect()
		)$n

	# split the sort input by comma and check if variant_ids in the resulting list, if not append to the list for unique sorting
	sort_list <- str_split(str_squish(sort), ",")[[1]]
	
	if ( !("variant_id" %in% sort) ){
		sort_list <- append(sort, "variant_id")
	}

	# check if `page[size]` is either "all" or a valid integer and convert or assign values accordingly
	if ( `page[size]` == "all" ){
		page_after <- 0
		page_size <- hnf1b_db_variant_rows
		page_count <- ceiling(hnf1b_db_variant_rows/page_size)
	} else if ( is.numeric(as.integer(`page[size]`)) )
	{
		page_after <- as.integer(`page[after]`)
		page_size <- as.integer(`page[size]`)
		page_count <- ceiling(hnf1b_db_variant_rows/page_size)
	} else
	{
		res$status <- 400 #Bad Request
		return(list(error="Invalid Parameter Value Error."))
	}

	# get data from database
	hnf1b_db_variant_table <- pool %>% 
		tbl("report_variant_view") %>%
		arrange(!!!syms(sort_list)) %>%
		collect()

	# find the current row of the requested page_after entry
	page_after_row <- (hnf1b_db_variant_table %>%
		mutate(row = row_number()) %>%
		filter(variant_id == page_after)
		)$row

	if ( length(page_after_row) == 0 ){
		page_after_row <- 0
		page_after_row_next <- ( hnf1b_db_variant_table %>%
			filter(row_number() == page_after_row + page_size + 1) )$variant_id
	} else {
		page_after_row_next <- ( hnf1b_db_variant_table %>%
			filter(row_number() == page_after_row + page_size) )$variant_id
	}

	# find next and prev item row
	page_after_row_prev <- ( hnf1b_db_variant_table %>%
		filter(row_number() == page_after_row - page_size) )$variant_id
	page_after_row_last <- ( hnf1b_db_variant_table %>%
		filter(row_number() ==  page_size * (page_count - 1) ) )$variant_id
		
	# filter by row
	hnf1b_db_variant_collected <- hnf1b_db_variant_table %>%
		filter(row_number() > page_after_row & row_number() <= page_after_row + page_size)

	# generate links for self, next and prev pages
	self <- paste0("http://", dw$host, ":", dw$port_self, "/api/variants/?sort=", sort, "&page[after]=", `page[after]`, "&page[size]=", `page[size]`)
	if ( length(page_after_row_prev) == 0 ){
		prev <- "null"
	} else
	{
		prev <- paste0("http://", dw$host, ":", dw$port_self, "/api/variants?sort=", sort, "&page[after]=", page_after_row_prev, "&page[size]=", `page[size]`)
	}
	
	if ( length(page_after_row_next) == 0 ){
		`next` <- "null"
	} else
	{
		`next` <- paste0("http://", dw$host, ":", dw$port_self, "/api/variants?sort=", sort, "&page[after]=", page_after_row_next, "&page[size]=", `page[size]`)
	}
	
	if ( length(page_after_row_last) == 0 ){
		last <- "null"
	} else
	{
		last <- paste0("http://", dw$host, ":", dw$port_self, "/api/variants?sort=", sort, "&page[after]=", page_after_row_last, "&page[size]=", `page[size]`)
	}

	links <- as_tibble(list("prev" = prev, "self" = self, "next" = `next`, "last" = last))

	# 
	list(links = links, data = hnf1b_db_variant_collected)
}


## Variant endpoints
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Publication endpoints

#* @tag publication
## get all publications
#* @serializer json list(na="string")
#' @get /api/publications
function(res, sort = "publication_id", `page[after]` = 0, `page[size]` = "all") {

	# get number of rows in publication
	hnf1b_db_publication_rows <- (pool %>% 
		tbl("publication") %>%
		summarise(n = n()) %>%
		collect()
		)$n

	# split the sort input by comma and check if publication_ids in the resulting list, if not append to the list for unique sorting
	sort_list <- str_split(str_squish(sort), ",")[[1]]
	
	if ( !("publication_id" %in% sort) ){
		sort_list <- append(sort, "publication_id")
	}

	# check if `page[size]` is either "all" or a valid integer and convert or assign values accordingly
	if ( `page[size]` == "all" ){
		page_after <- 0
		page_size <- hnf1b_db_publication_rows
		page_count <- ceiling(hnf1b_db_publication_rows/page_size)
	} else if ( is.numeric(as.integer(`page[size]`)) )
	{
		page_after <- as.integer(`page[after]`)
		page_size <- as.integer(`page[size]`)
		page_count <- ceiling(hnf1b_db_publication_rows/page_size)
	} else
	{
		res$status <- 400 #Bad Request
		return(list(error="Invalid Parameter Value Error."))
	}

	# get data from database
	hnf1b_db_publication_table <- pool %>% 
		tbl("publication") %>%
		arrange(!!!syms(sort_list)) %>%
		collect()

	# find the current row of the requested page_after entry
	page_after_row <- (hnf1b_db_publication_table %>%
		mutate(row = row_number()) %>%
		filter(publication_id == page_after)
		)$row

	if ( length(page_after_row) == 0 ){
		page_after_row <- 0
		page_after_row_next <- ( hnf1b_db_publication_table %>%
			filter(row_number() == page_after_row + page_size + 1) )$publication_id
	} else {
		page_after_row_next <- ( hnf1b_db_publication_table %>%
			filter(row_number() == page_after_row + page_size) )$publication_id
	}

	# find next and prev item row
	page_after_row_prev <- ( hnf1b_db_publication_table %>%
		filter(row_number() == page_after_row - page_size) )$publication_id
	page_after_row_last <- ( hnf1b_db_publication_table %>%
		filter(row_number() ==  page_size * (page_count - 1) ) )$publication_id
		
	# filter by row
	hnf1b_db_publication_collected <- hnf1b_db_publication_table %>%
		filter(row_number() > page_after_row & row_number() <= page_after_row + page_size)

	# generate links for self, next and prev pages
	self <- paste0("http://", dw$host, ":", dw$port_self, "/api/publications/?sort=", sort, "&page[after]=", `page[after]`, "&page[size]=", `page[size]`)
	if ( length(page_after_row_prev) == 0 ){
		prev <- "null"
	} else
	{
		prev <- paste0("http://", dw$host, ":", dw$port_self, "/api/publications?sort=", sort, "&page[after]=", page_after_row_prev, "&page[size]=", `page[size]`)
	}
	
	if ( length(page_after_row_next) == 0 ){
		`next` <- "null"
	} else
	{
		`next` <- paste0("http://", dw$host, ":", dw$port_self, "/api/publications?sort=", sort, "&page[after]=", page_after_row_next, "&page[size]=", `page[size]`)
	}
	
	if ( length(page_after_row_last) == 0 ){
		last <- "null"
	} else
	{
		last <- paste0("http://", dw$host, ":", dw$port_self, "/api/publications?sort=", sort, "&page[after]=", page_after_row_last, "&page[size]=", `page[size]`)
	}

	links <- as_tibble(list("prev" = prev, "self" = self, "next" = `next`, "last" = last))

	# 
	list(links = links, data = hnf1b_db_publication_collected)
}

## Publication endpoints
##-------------------------------------------------------------------##