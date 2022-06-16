# api_plumber.R
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
library(RCurl)
library(stringdist)
library(xlsx)
library(easyPubMed)
library(rvest)
library(lubridate)
library(pool)
library(memoise)
library(coop)
library(timetk)
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
source("functions/helper-functions.R", local = TRUE)

# Memoise functions

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

  report_phenotype_nested <- pool %>%
    tbl("report_phenotype_view") %>%
    collect() %>%
    nest(phenotypes = -c(report_id, individual_id))

  hnf1b_db_report_table <- pool %>%
    tbl("report_view") %>%
    collect() %>%
    left_join(report_phenotype_nested, by = c("report_id",
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
  ind_plus_report_pag_info <-
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
  meta <- ind_plus_report_pag_info$meta %>%
    add_column(as_tibble(list("sort" = sort,
    "filter" = filter,
    "fields" = fields,
    "executionTime" = execution_time)))

  # add host, port and other information to links from
  # the link information from generate_cursor_pagination_info function return
  links <- ind_plus_report_pag_info$links %>%
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
    data = ind_plus_report_pag_info$data
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
  variant_table <- pool %>%
    tbl("report_variant_view") %>%
    collect() %>%
    arrange(!!!rlang::parse_exprs(sort_exprs)) %>%
    filter(!!!rlang::parse_exprs(filter_exprs))

  variants <- variant_table %>%
    select(-individual_id, -report_id, -detection_method, -segregation) %>%
    mutate(criteria_classification = as.list(str_split(criteria_classification,
      pattern = ", "))) %>%
    unique()

  variants_reports <- variant_table %>%
    select(variant_id,
      individual_id,
      report_id,
      detection_method,
      segregation) %>%
    nest_by(variant_id, .key = "reports") %>%
    ungroup()

  variant_table_nested <- variants %>%
    left_join(variants_reports, by = c("variant_id"))

  # select fields from table based on input
  # using the helper function "select_tibble_fields"
  variant_table_nested <- select_tibble_fields(variant_table_nested,
    fields,
    "variant_id")

  # use the helper generate_cursor_pagination_info
  # to generate cursor pagination information from a tibble
  variant_table_nested_pag_info <- generate_cursor_pagination_info(
    variant_table_nested,
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
  meta <- variant_table_nested_pag_info$meta %>%
    add_column(as_tibble(list("sort" = sort,
      "filter" = filter,
      "fields" = fields,
      "executionTime" = execution_time))
    )

  # add host, port and other information to links from the link
  # information from generate_cursor_pagination_info function return
  links <- variant_table_nested_pag_info$links %>%
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
  list(links = links, meta = meta, data = variant_table_nested_pag_info$data)
}


#* @tag variant
## get all HNF1B domains
#* @serializer json list(na="null")
#' @get /api/domains
function(feature_key = "protein,domain,site") {

  # split feature_key input
  # to do: add check for input and whetehr the values exists in the table
  feature_key_tibble <- as_tibble(str_split(feature_key, ",")[[1]]) %>%
    select(key = value)

  # get data from database
  domain_table <- pool %>%
    tbl("domains") %>%
    collect() %>%
    filter(FeatureKey %in% feature_key_tibble$key)

  # generate object to return
  list(data = domain_table)
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
#* gets publication development over time
#* @serializer json list(na="string")
#' @get /api/statistics/publications_over_time
function(res) {

  start_time <- Sys.time()

  # get publication from the publication view
  publications <- pool %>%
    tbl("publication") %>%
    select(publication_id, publication_type, publication_date) %>%
    collect() %>%
    filter(!is.na(publication_date)) %>%
    mutate(publication_date = as.Date(publication_date)) %>%
    mutate(count = 1) %>%
    arrange(publication_date) %>%
    group_by(publication_type) %>%
    summarise_by_time(
      .date_var = publication_date,
      .by       = "month", # Setup for monthly aggregation
      # Summarization
      count  = sum(count)
    ) %>%
    mutate(cumulative_count = cumsum(count)) %>%
    ungroup() %>%
    mutate(publication_date = strftime(publication_date, "%Y-%m-%d"))

  # generate object to return
  publications_nested <- publications %>%
    nest_by(publication_type, .key = "values") %>%
    ungroup() %>%
    select("group" = publication_type, values)

  # compute execution time
  end_time <- Sys.time()
  execution_time <- as.character(paste0(round(end_time - start_time, 2),
  " secs"))

  # add columns to the meta information from
  # generate_cursor_pag_inf function return
  meta <- tibble::as_tibble(list(
    "max_count" = max(publications$count),
    "max_cumulative_count" = max(publications$cumulative_count),
    "executionTime" = execution_time))

  # generate object to return
  list(meta = meta, data = publications_nested)
}


#* @tag statistics
#* gets reported phenotypes in a cohort
#* @serializer json list(na="string")
#' @get /api/statistics/phenotypes_in_cohort
function(res) {

  start_time <- Sys.time()

  # get phenotypes
  phenotype_view <- pool %>%
    tbl("report_phenotype_view") %>%
    collect() %>%
    arrange(individual_id, phenotype_name) %>%
    select(individual_id, group = phenotype_name, described, described_id) %>%
    group_by(individual_id, group) %>%
    filter(described_id == min(described_id)) %>%
    unique() %>%
    ungroup() %>%
    select(-described_id) %>%
    group_by(group, described) %>%
    summarise(count = n(), .groups = "drop") %>%
    ungroup() %>%
    pivot_wider(names_from = described, values_from = count) %>%
    filter(yes / (yes + no) > 0.10) %>%
    pivot_longer(cols = no:yes, names_to = c("described"),
      values_to = "count") %>%
    pivot_wider(names_from = described, values_from = count) %>%
    arrange(desc(yes))

  # compute execution time
  end_time <- Sys.time()
  execution_time <- as.character(paste0(round(end_time - start_time, 2),
  " secs"))

  # add columns to the meta information from
  # generate_cursor_pag_inf function return
  meta <- tibble::as_tibble(list(
    "executionTime" = execution_time))

  # generate object to return
  list(meta = meta, data = phenotype_view)
}


#* @tag statistics
#* gets cohort characteristics
#* @serializer json list(na="string")
#' @get /api/statistics/cohort_characteristics
function(res) {

  start_time <- Sys.time()

  # get phenotypes
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

    # generate indivdual sublists
    individual_sex <- individual_plus_report_table %>%
        group_by(sex) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        pivot_wider(names_from = sex, values_from = count)

    individual_cohort <- individual_plus_report_table %>%
        group_by(cohort) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        pivot_wider(names_from = cohort, values_from = count)

    individual_multiple <- individual_plus_report_table %>%
        group_by(reported_multiple) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        mutate(reported_multiple =
        case_when(
            reported_multiple == 1 ~ "multiple",
            reported_multiple == 0 ~ "single"
        )
        ) %>%
        pivot_wider(names_from = reported_multiple, values_from = count)

    cohort_characteristics <- list(sex = individual_sex,
        cohort = individual_cohort,
        reported = individual_multiple)

  # compute execution time
  end_time <- Sys.time()
  execution_time <- as.character(paste0(round(end_time - start_time, 2),
  " secs"))

  # add columns to the meta information from
  # generate_cursor_pag_inf function return
  meta <- tibble::as_tibble(list(
    "executionTime" = execution_time))

  # generate object to return
  list(meta = meta, data = cohort_characteristics)
}


#* @tag statistics
#* gets variant characteristics
#* @serializer json list(na="string")
#' @get /api/statistics/variant_characteristics
function(res) {

  start_time <- Sys.time()

  # get variants
  # get data from report_variant_view
  variant_table <- pool %>%
    tbl("report_variant_view") %>%
    collect() %>%
    select(variant_id,
        detection_method,
        segregation,
        variant_class,
        IMPACT,
        EFFECT,
        verdict_classification) %>%
    arrange(variant_id)

    # generate sublists
    variant_detection_method <- variant_table %>%
        group_by(detection_method) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        pivot_wider(names_from = detection_method, values_from = count)

    variant_segregation <- variant_table %>%
        group_by(segregation) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        pivot_wider(names_from = segregation, values_from = count)

    variant_class <- variant_table %>%
        select(-detection_method, -segregation) %>%
        unique() %>%
        group_by(variant_class) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        pivot_wider(names_from = variant_class, values_from = count)

    variant_impact <- variant_table %>%
        select(-detection_method, -segregation) %>%
        unique() %>%
        group_by(IMPACT) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        pivot_wider(names_from = IMPACT, values_from = count)

    variant_effect <- variant_table %>%
        select(-detection_method, -segregation) %>%
        unique() %>%
        group_by(EFFECT) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        pivot_wider(names_from = EFFECT, values_from = count)

    variant_classification <- variant_table %>%
        select(-detection_method, -segregation) %>%
        unique() %>%
        group_by(verdict_classification) %>%
        summarise(count = n()) %>%
        ungroup() %>%
        pivot_wider(names_from = verdict_classification, values_from = count)

  # combine into one list
    variant_characteristics <- list(
        detection_method = variant_detection_method,
        segregation = variant_segregation,
        class = variant_class,
        impact = variant_impact,
        effect = variant_effect,
        classification = variant_classification
    )

  # compute execution time
  end_time <- Sys.time()
  execution_time <- as.character(paste0(round(end_time - start_time, 2),
  " secs"))

  # add columns to the meta information from
  # generate_cursor_pag_inf function return
  meta <- tibble::as_tibble(list(
    "executionTime" = execution_time))

  # generate object to return
  list(meta = meta, data = variant_characteristics)
}


#* @tag statistics
## get statistics of the database entries
#* @serializer json list(na="null")
#' @get /api/statistics/database_statistics
function() {

  # get statistics from the statistics view
  statistics <- pool %>%
    tbl("statistics") %>%
    collect()

  # generate object to return
  statistics
}

## Statistics endpoints
##-------------------------------------------------------------------##