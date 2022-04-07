# hnf1b-db_plumber.R
## to do: adapt "serializer json list(na="null")"

##-------------------------------------------------------------------##
# load libraries
library(plumber)
library(tidyverse)
library(cowplot)
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

# load source files
source("functions/plot-functions.R")
source("functions/helper-functions.R")

# Memoise functions
make_publications_plot_mem <- memoise(make_publications_plot)
make_cohort_plot_mem <- memoise(make_cohort_plot)

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
#* @apiTag statistics Database statistics
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

#* @tag individual
## get all individuals
#* @serializer json list(na="string")
#' @get /api/individuals
function(res, sort = "individual_id", `page[after]` = 0, `page[size]` = "all") {

	# get number of rows in individual table
	hnf1b_db_individual_rows <- (pool %>% 
		tbl("individual") %>%
		summarise(n = n()) %>%
		collect()
		)$n

	# split the sort input by comma and check if individual_id in the resulting list, if not append to the list for unique sorting
	sort_list <- str_split(str_squish(sort), ",")[[1]]
	
	if ( !("individual_id" %in% sort) ){
		sort_list <- append(sort, "individual_id")
	}

	# check if `page[size]` is either "all" or a valid integer and convert or assign values accordingly
	if ( `page[size]` == "all" ){
		page_after <- 0
		page_size <- hnf1b_db_individual_rows
		page_count <- ceiling(hnf1b_db_individual_rows/page_size)
	} else if ( is.numeric(as.integer(`page[size]`)) )
	{
		page_after <- as.integer(`page[after]`)
		page_size <- as.integer(`page[size]`)
		page_count <- ceiling(hnf1b_db_individual_rows/page_size)
	} else
	{
		res$status <- 400 #Bad Request
		return(list(error="Invalid Parameter Value Error."))
	}

	# get data from database
	hnf1b_db_individual_table <- pool %>% 
		tbl("individual")

	hnf1b_db_report_table <- pool %>% 
		tbl("report_view")

	hnf1b_db_individual_plus_report_table <- hnf1b_db_individual_table %>% 
		left_join(hnf1b_db_report_table, by = c("individual_id")) %>%
		collect() %>%
		arrange(desc(report_date)) %>%
		arrange(!!!syms(sort_list)) %>%
		nest(reports = -c(individual_id, sex, individual_DOI))

	# find the current row of the requested page_after entry
	page_after_row <- (hnf1b_db_individual_plus_report_table %>%
		mutate(row = row_number()) %>%
		filter(individual_id == page_after)
		)$row

	if ( length(page_after_row) == 0 ){
		page_after_row <- 0
		page_after_row_next <- ( hnf1b_db_individual_plus_report_table %>%
			filter(row_number() == page_after_row + page_size + 1) )$individual_id
	} else {
		page_after_row_next <- ( hnf1b_db_individual_plus_report_table %>%
			filter(row_number() == page_after_row + page_size) )$individual_id
	}

	# find next and prev item row
	page_after_row_prev <- ( hnf1b_db_individual_plus_report_table %>%
		filter(row_number() == page_after_row - page_size) )$individual_id
	page_after_row_last <- ( hnf1b_db_individual_plus_report_table %>%
		filter(row_number() ==  page_size * (page_count - 1) ) )$individual_id
		
	# filter by row
	hnf1b_db_report_collected <- hnf1b_db_individual_plus_report_table %>%
		filter(row_number() > page_after_row & row_number() <= page_after_row + page_size)

	# generate links for self, next and prev pages
	self <- paste0("http://", dw$host, ":", dw$port_self, "/api/individuals/?sort=", sort, "&page[after]=", `page[after]`, "&page[size]=", `page[size]`)
	if ( length(page_after_row_prev) == 0 ){
		prev <- "null"
	} else
	{
		prev <- paste0("http://", dw$host, ":", dw$port_self, "/api/individuals?sort=", sort, "&page[after]=", page_after_row_prev, "&page[size]=", `page[size]`)
	}
	
	if ( length(page_after_row_next) == 0 ){
		`next` <- "null"
	} else
	{
		`next` <- paste0("http://", dw$host, ":", dw$port_self, "/api/individuals?sort=", sort, "&page[after]=", page_after_row_next, "&page[size]=", `page[size]`)
	}
	
	if ( length(page_after_row_last) == 0 ){
		last <- "null"
	} else
	{
		last <- paste0("http://", dw$host, ":", dw$port_self, "/api/individuals?sort=", sort, "&page[after]=", page_after_row_last, "&page[size]=", `page[size]`)
	}

	links <- as_tibble(list("prev" = prev, "self" = self, "next" = `next`, "last" = last))

	# 
	list(links = links, data = hnf1b_db_report_collected)
}

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



##-------------------------------------------------------------------##
## Statistics endpoints

#* @tag statistics
## get statistics of the database entries
#* @serializer json list(na="string")
#' @get /api/statistics
function() {

	# get statistics from the statistics view
	statistics <- pool %>% 
		tbl("statistics") %>%
		collect()
		
	statistics

}


#* @tag statistics
## get statistics of the database entries
#* @serializer text
#' @get /api/statistics/publications_plot
function() {

	# get publication from the publication view
	hnf1b_db_publications <- pool %>% 
		tbl("publication") %>%
		select(publication_id, publication_type, publication_date) %>%
		collect() %>%
		filter(!is.na(publication_date)) %>%
		mutate(publication_date = as.Date(publication_date))

	make_publications_plot(hnf1b_db_publications)

}


#* @tag statistics
## get statistics of the cohort
#* @serializer text
#' @get /api/statistics/cohort_plot
function() {

	# get data from individual table and report view and combine
	hnf1b_db_individual_table <- pool %>% 
		tbl("individual")

	hnf1b_db_report_table <- pool %>% 
		tbl("report_view")

	hnf1b_db_individual_plus_report_table <- hnf1b_db_individual_table %>% 
		left_join(hnf1b_db_report_table, by = c("individual_id")) %>%
		collect() %>%
		arrange(desc(report_date)) %>%
		mutate(report_date = 
			case_when(
				is.na(report_date) ~ Sys.Date(),
				!is.na(report_date)~ as.Date(report_date)
			)
		) %>%
		group_by(individual_id) %>%
		filter(report_date == max(report_date)) %>%
		select(individual_id, sex, report_date, cohort, reported_multiple) %>%
		arrange(individual_id) %>%
		ungroup()

	make_cohort_plot(hnf1b_db_individual_plus_report_table)

}


#* @tag statistics
## get statistics of the cohort
#* @serializer text
#' @get /api/statistics/phenotype_plot
function() {

	# get data from database
	hnf1b_db_report_phenotype_view <- pool %>% 
		tbl("report_phenotype_view") %>% 
		collect() %>%
		arrange(individual_id, phenotype_name) %>%
		filter(!is.na(phenotype_name)) %>%
		select(individual_id, phenotype_name, described) %>%
		mutate(described = 
			case_when(
				described == "yes" ~ 2,
				described == "no" ~ 1,
				described == "not reported" ~ 0,
			)
		) %>%
		group_by(individual_id, phenotype_name) %>%
		filter(described == max(described)) %>%
		ungroup()



	hnf1b_db_phenotypes <- hnf1b_db_report_phenotype_view %>%
		filter(!str_detect(phenotype_name, "Stage")) %>% 
		group_by(phenotype_name, described) %>%
		mutate(described = 
			case_when(
				described == 2 ~ "yes",
				described == 1 ~ "no",
				described == 0 ~ "not reported",
			)
		) %>%
		summarise(count = n(), .groups = 'drop') %>%
		ungroup() %>%
		pivot_wider(names_from = described, values_from = count) %>%
		filter(yes/(yes + no + `not reported`) >0.15) %>%
		pivot_longer(cols = no:yes, names_to = c("described"), values_to = "count")
		

	## set factors
	hnf1b_db_phenotypes$phenotype_name <- factor(hnf1b_db_phenotypes$phenotype_name, levels=(hnf1b_db_phenotypes %>% filter(described=="yes") %>% arrange(count))$phenotype_name)


	phenotype_plot <- ggplot(hnf1b_db_phenotypes, aes(fill=described, x=count, y=phenotype_name)) + 
		geom_bar(position="fill", stat="identity") +
		scale_fill_manual(values=c("#5F9EA0", "#E1B378", "black")) +
		geom_vline(xintercept=0.14, linetype="dashed", color = "red", size=0.7) +
		theme_classic() +
		theme(axis.text.x = element_text(angle = 0, hjust = 0), axis.title.x = element_blank(), axis.title.y = element_blank(), legend.position="top")

	file <- "results/phenotype_plot.png"
	ggsave(file, phenotype_plot, width = 5.5, height = 3.0, dpi = 150, units = "in")
	return(base64Encode(readBin(file, "raw", n = file.info(file)$size), "txt"))

}

## Statistics endpoints
##-------------------------------------------------------------------##