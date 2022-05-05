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
dw <- config::get(Sys.getenv("API_CONFIG"))
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

#* @apiDescription This is the API powering the HNF1B-db website
#* @apiDescription  and allowing programmatic access to the database contents.
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
    res$setHeader("Access-Control-Allow-Methods",
      "*")
    res$setHeader("Access-Control-Allow-Headers",
      req$HTTP_ACCESS_CONTROL_REQUEST_HEADERS)
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
#* @serializer json list(na="null")
#' @get /api/reports
function(res,
  sort = "report_id",
  filter = "",
  fields = "",
  `page[after]` = 0,
  `page[size]` = "all") {

  start_time <- Sys.time()

  # generate sort expression based on sort input
  sort_exprs <- generate_sort_expressions(sort, unique_id = "report_id")

  # generate filter expression based on filter input
  filter_exprs <- generate_filter_expressions(filter)

  # get data from database
  hnf1b_db_report_table <- pool %>%
    tbl("report_view") %>%
    collect() %>%
    arrange(!!!rlang::parse_exprs(sort_exprs)) %>%
    filter(!!!rlang::parse_exprs(filter_exprs))

  # select fields from table based on input
  # using the helper function "select_tibble_fields"
  hnf1b_db_report_table <- select_tibble_fields(
    hnf1b_db_report_table,
    fields,
    "report_id")

  # use the helper generate_cursor_pagination_info
  # to generate cursor pagination information from a tibble
  hnf1b_db_report_table <- generate_cursor_pagination_info(
    hnf1b_db_report_table,
    `page[size]`,
    `page[after]`,
    "report_id"
  )

  # compute execution time
  end_time <- Sys.time()
  execution_time <- as.character(paste0(round(end_time - start_time, 2),
    " secs"))

  # add columns to the meta information from
  # generate_cursor_pagination_info function return
  meta <- hnf1b_db_report_table$meta %>%
    add_column(as_tibble(list("sort" = sort,
      "filter" = filter,
      "fields" = fields,
      "executionTime" = execution_time))
    )

  # add host, port and other information to links from the link
  # information from generate_cursor_pagination_info function return
  links <- hnf1b_db_report_table$links %>%
      pivot_longer(everything(), names_to = "type", values_to = "link") %>%
    mutate(link = case_when(
      link != "null" ~ paste0("http://",
        dw$host, ":",
        dw$port_self,
        "/api/reports?sort=",
        sort,
        ifelse(filter != "", paste0("&filter=", filter), ""),
        ifelse(fields != "", paste0("&fields=", fields), ""),
        link),
      link == "null" ~ "null"
    )) %>%
      pivot_wider(everything(), names_from = "type", values_from = "link")

  # generate object to return
  list(links = links, meta = meta, data = hnf1b_db_report_table$data)
}

## Report endpoints
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Individual endpoints

#* @tag individual
## get all individuals
#* @serializer json list(na="null")
#' @get /api/individuals
function(res,
  sort = "individual_id",
  filter = "",
  fields = "",
  `page[after]` = 0,
  `page[size]` = "all") {

  start_time <- Sys.time()

  # generate sort expression based on sort input
  sort_exprs <- generate_sort_expressions(sort, unique_id = "individual_id")

  # generate filter expression based on filter input
  filter_exprs <- generate_filter_expressions(filter)

  # get data from database
  hnf1b_db_individual_table <- pool %>%
    tbl("individual") %>%
    collect()

  hnf1b_db_report_phenotype_nested <- pool %>%
    tbl("report_phenotype_view") %>%
    collect() %>%
    nest(phenotypes = -c(report_id, individual_id))

  hnf1b_db_report_table <- pool %>%
    tbl("report_view") %>%
    collect() %>%
    left_join(hnf1b_db_report_phenotype_nested, by = c("report_id",
      "individual_id"))

  individual_plus_report_table <- hnf1b_db_individual_table %>%
    left_join(hnf1b_db_report_table, by = c("individual_id")) %>%
    nest(reports = -c(individual_id, sex, individual_DOI)) %>%
    arrange(!!!rlang::parse_exprs(sort_exprs)) %>%
    filter(!!!rlang::parse_exprs(filter_exprs))

  # select fields from table based on input
  # using the helper function "select_tibble_fields"
  individual_plus_report_table <- select_tibble_fields(
    individual_plus_report_table,
    fields,
    "individual_id"
  )

  # use the helper generate_cursor_pagination_info
  # to generate cursor pagination information from a tibble
  individual_plus_report_pag_info <-
  generate_cursor_pagination_info(
    individual_plus_report_table,
    `page[size]`,
    `page[after]`,
    "individual_id")

  # compute execution time
  end_time <- Sys.time()
  execution_time <- as.character(paste0(round(end_time - start_time, 2),
  " secs"))

  # add columns to the meta information from
  # generate_cursor_pagination_info function return
  meta <- individual_plus_report_pag_info$meta %>%
    add_column(as_tibble(list("sort" = sort,
    "filter" = filter,
    "fields" = fields,
    "executionTime" = execution_time)))

  # add host, port and other information to links from
  # the link information from generate_cursor_pagination_info function return
  links <- individual_plus_report_pag_info$links %>%
      pivot_longer(everything(), names_to = "type", values_to = "link") %>%
    mutate(link = case_when(
      link != "null" ~ paste0("http://",
        dw$host,
        ":",
        dw$port_self,
        "/api/individuals?sort=",
        sort,
        ifelse(filter != "", paste0("&filter=", filter), ""),
        ifelse(fields != "", paste0("&fields=", fields), ""),
        link),
      link == "null" ~ "null"
    )) %>%
      pivot_wider(everything(), names_from = "type", values_from = "link")

  # generate object to return
  list(links = links,
    meta = meta,
    data = individual_plus_report_pag_info$data
  )
}

## Individual endpoints
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Variant endpoints

#* @tag variant
## get all variants
#* @serializer json list(na="null")
#' @get /api/variants
function(res,
  sort = "variant_id",
  filter = "",
  fields = "",
  `page[after]` = 0,
  `page[size]` = "all") {

  start_time <- Sys.time()

  # generate sort expression based on sort input
  sort_exprs <- generate_sort_expressions(sort, unique_id = "report_id")

  # generate filter expression based on filter input
  filter_exprs <- generate_filter_expressions(filter)

  # get data from database
  hnf1b_db_variant_table <- pool %>%
    tbl("report_variant_view") %>%
    collect() %>%
    arrange(!!!rlang::parse_exprs(sort_exprs)) %>%
    filter(!!!rlang::parse_exprs(filter_exprs))

  # select fields from table based on input
  # using the helper function "select_tibble_fields"
  hnf1b_db_variant_table <- select_tibble_fields(hnf1b_db_variant_table,
    fields,
    "variant_id")

  # use the helper generate_cursor_pagination_info
  # to generate cursor pagination information from a tibble
  hnf1b_db_variant_table_pag_info <- generate_cursor_pagination_info(
    hnf1b_db_variant_table,
    `page[size]`,
    `page[after]`,
    "variant_id"
  )

  # compute execution time
  end_time <- Sys.time()
  execution_time <- as.character(paste0(round(end_time - start_time, 2),
    " secs"))

  # add columns to the meta information from
  # generate_cursor_pagination_info function return
  meta <- hnf1b_db_variant_table_pag_info$meta %>%
    add_column(as_tibble(list("sort" = sort,
      "filter" = filter,
      "fields" = fields,
      "executionTime" = execution_time))
    )

  # add host, port and other information to links from the link
  # information from generate_cursor_pagination_info function return
  links <- hnf1b_db_variant_table_pag_info$links %>%
      pivot_longer(everything(), names_to = "type", values_to = "link") %>%
    mutate(link = case_when(
      link != "null" ~ paste0("http://",
        dw$host,
        ":",
        dw$port_self,
        "/api/variants?sort=",
        sort,
        ifelse(filter != "", paste0("&filter=", filter), ""),
        ifelse(fields != "", paste0("&fields=", fields), ""),
        link),
      link == "null" ~ "null"
    )) %>%
      pivot_wider(everything(), names_from = "type", values_from = "link")

  # generate object to return
  list(links = links, meta = meta, data = hnf1b_db_variant_table_pag_info$data)
}


## Variant endpoints
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Publication endpoints

#* @tag publication
## get all publications
#* @serializer json list(na="null")
#' @get /api/publications
function(res,
  sort = "publication_id",
  filter = "",
  fields = "",
  `page[after]` = 0,
  `page[size]` = "all") {

  start_time <- Sys.time()

  # generate sort expression based on sort input
  sort_exprs <- generate_sort_expressions(sort, unique_id = "publication_id")

  # generate filter expression based on filter input
  filter_exprs <- generate_filter_expressions(filter)

  # get data from database
  hnf1b_db_publication_table <- pool %>%
    tbl("publication") %>%
    collect() %>%
    arrange(!!!rlang::parse_exprs(sort_exprs)) %>%
    filter(!!!rlang::parse_exprs(filter_exprs))

  # select fields from table based on input
  # using the helper function "select_tibble_fields"
  hnf1b_db_publication_table <- select_tibble_fields(hnf1b_db_publication_table,
    fields,
    "publication_id")

  # use the helper generate_cursor_pagination_info
  # to generate cursor pagination information from a tibble
  publication_tab_pag_info <- generate_cursor_pagination_info(
    hnf1b_db_publication_table,
    `page[size]`,
    `page[after]`,
    "publication_id"
  )

  # compute execution time
  end_time <- Sys.time()
  execution_time <- as.character(paste0(round(end_time - start_time, 2),
  " secs"))

  # add columns to the meta information from
  # generate_cursor_pagination_info function return
  meta <- publication_tab_pag_info$meta %>%
    add_column(as_tibble(list("sort" = sort,
      "filter" = filter,
      "fields" = fields,
      "executionTime" = execution_time))
    )

  # add host, port and other information to links from the link
  # information from generate_cursor_pagination_info function return
  links <- publication_tab_pag_info$links %>%
      pivot_longer(everything(), names_to = "type", values_to = "link") %>%
    mutate(link = case_when(
      link != "null" ~ paste0("http://",
        dw$host,
        ":",
        dw$port_self,
        "/api/publications?sort=",
        sort,
        ifelse(filter != "", paste0("&filter=", filter), ""),
        ifelse(fields != "", paste0("&fields=", fields), ""),
        link),
      link == "null" ~ "null"
    )) %>%
      pivot_wider(everything(), names_from = "type", values_from = "link")

  # generate object to return
  list(links = links, meta = meta, data = publication_tab_pag_info$data)
}

## Publication endpoints
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Statistics endpoints

#* @tag statistics
## get statistics of the database entries
#* @serializer json list(na="null")
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

  individual_plus_report_table <- hnf1b_db_individual_table %>%
    left_join(hnf1b_db_report_table, by = c("individual_id")) %>%
    collect() %>%
    arrange(desc(report_date)) %>%
    mutate(report_date =
      case_when(
        is.na(report_date) ~ Sys.Date(),
        !is.na(report_date) ~ as.Date(report_date)
      )
    ) %>%
    group_by(individual_id) %>%
    filter(report_date == max(report_date)) %>%
    select(individual_id, sex, report_date, cohort, reported_multiple) %>%
    arrange(individual_id) %>%
    ungroup()

  make_cohort_plot(individual_plus_report_table)

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
    summarise(count = n(), .groups = "drop") %>%
    ungroup() %>%
    pivot_wider(names_from = described, values_from = count) %>%
    filter(yes / (yes + no + `not reported`) > 0.15) %>%
    pivot_longer(cols = no:yes, names_to = c("described"), values_to = "count")


  ## set factors
  hnf1b_db_phenotypes$phenotype_name <- factor(
    hnf1b_db_phenotypes$phenotype_name,
    levels=(hnf1b_db_phenotypes %>%
      filter(described == "yes") %>%
      arrange(count))$phenotype_name
    )

  phenotype_plot <- ggplot(hnf1b_db_phenotypes,
      aes(fill=described,
      x=count, y=phenotype_name)) +
    geom_bar(position="fill", stat="identity") +
    scale_fill_manual(values=c("#5F9EA0", "#E1B378", "black")) +
    geom_vline(xintercept=0.14, linetype="dashed", color = "red", size=0.7) +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 0, hjust = 0),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      legend.position="top")

  file <- "results/phenotype_plot.png"
  ggsave(file, phenotype_plot,
    width = 5.5, height = 3.0,
    dpi = 150, units = "in")
  return(base64Encode(readBin(file, "raw", n = file.info(file)$size), "txt"))

}

## Statistics endpoints
##-------------------------------------------------------------------##