# api_plumber.R
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
library(blastula)
library(keyring)
library(rlang)
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## load config file
dw <- config::get(Sys.getenv("API_CONFIG"))
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## if not available set the enverinment variable for the noreply mail
if (nchar(Sys.getenv("SMTP_PASSWORD")) == 0) {
  Sys.setenv("SMTP_PASSWORD" = toString(dw$mail_noreply_password))
}
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
# Global API functions
options("plumber.apiURL" = dw$base_url)

# load source files
source("functions/helper-functions.R", local = TRUE)

# Memoise functions

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
#* @apiTag user User account related endpoints
#* @apiTag authentication Authentication related endpoints
##-------------------------------------------------------------------##
##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## hooks

#* @plumber
function(pr) {

  pr %>%
    plumber::pr_hook("exit", function() {
      pool::poolClose(pool)
      message("Disconnected")
    })
}
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


#* @filter check_signin
#* checks signin from header token and set user variable to request
function(req, res) {
  # load secret and convert to raw
  key <- charToRaw(dw$secret)

  if (req$REQUEST_METHOD == "GET" && is.null(req$HTTP_AUTHORIZATION)) {
    plumber::forward()
  } else if (req$REQUEST_METHOD == "GET" && !is.null(req$HTTP_AUTHORIZATION)) {
    # load jwt from header
    jwt <- str_remove(req$HTTP_AUTHORIZATION, "Bearer ")
    # decode jwt
    user <- jwt_decode_hmac(str_remove(req$HTTP_AUTHORIZATION, "Bearer "),
      secret = key)
    # add user_id and user_role as value to request
    req$user_id <- as.integer(user$user_id)
    req$user_role <- user$user_role
    # and forward request
    plumber::forward()
  } else if (req$REQUEST_METHOD == "POST" &&
      (req$PATH_INFO == "/api/gene/hash" ||
      req$PATH_INFO == "/api/entity/hash")) {
    # and forward request
    plumber::forward()
  } else {
    if (is.null(req$HTTP_AUTHORIZATION)) {
      res$status <- 401 # Unauthorized
      return(list(error = "Authorization http header missing."))
    } else if (jwt_decode_hmac(str_remove(req$HTTP_AUTHORIZATION, "Bearer "),
        secret = key)$exp < as.numeric(Sys.time())) {
      res$status <- 401 # Unauthorized
      return(list(error = "Token expired."))
    } else {
      # load jwt from header
      jwt <- str_remove(req$HTTP_AUTHORIZATION, "Bearer ")
      # decode jwt
      user <- jwt_decode_hmac(str_remove(req$HTTP_AUTHORIZATION, "Bearer "),
        secret = key)
      # add user_id and user_role as value to request
      req$user_id <- as.integer(user$user_id)
      req$user_role <- user$user_role
      # and forward request
      plumber::forward()
    }
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
  `page_after` = 0,
  `page_size` = "10") {

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
    `page_size`,
    `page_after`,
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
        dw$base_url,
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
  `page_after` = 0,
  `page_size` = "10") {

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
    `page_size`,
    `page_after`,
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
        dw$base_url,
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
  `page_after` = 0,
  `page_size` = "10") {

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
    `page_size`,
    `page_after`,
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
        dw$base_url,
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
  `page_after` = 0,
  `page_size` = "10") {

  start_time <- Sys.time()

  # generate sort expression based on sort input
  sort_exprs <- generate_sort_expressions(sort, unique_id = "publication_id")

  # generate filter expression based on filter input
  filter_exprs <- generate_filter_expressions(filter)

  # get data from database
  publication_table <- pool %>%
    tbl("report_publication_view") %>%
    collect() %>%
    arrange(!!!rlang::parse_exprs(sort_exprs)) %>%
    filter(!!!rlang::parse_exprs(filter_exprs))

  publications <- publication_table %>%
    select(-individual_id, -report_id) %>%
    unique()

  publications_reports <- publication_table %>%
    select(publication_id,
      individual_id,
      report_id) %>%
    nest_by(publication_id, .key = "reports") %>%
    ungroup()

  publication_table_nested <- publications %>%
    left_join(publications_reports, by = c("publication_id"))

  # select fields from table based on input
  # using the helper function "select_tibble_fields"
  publication_table_nested <- select_tibble_fields(publication_table_nested,
    fields,
    "publication_id")

  # use the helper generate_cursor_pagination_info
  # to generate cursor pagination information from a tibble
  publication_tab_pag_info <- generate_cursor_pagination_info(
    publication_table_nested,
    `page_size`,
    `page_after`,
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
        dw$base_url,
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



##-------------------------------------------------------------------##
## User endpoint section

#* @tag user
#* gets count statistics of all contributions of a user
#' @get /api/user/<user_id>/contributions
function(req, res, user_id) {

  user_requested <- user_id
  user <- req$user_id

  # first check rights
  if (length(user) == 0) {

    res$status <- 401 # Unauthorized
    return(list(error = "Please authenticate."))

  } else if (req$user_role %in% c("Administrator", "Reviewer")) {

  # get data from db view
  user_statistics <- pool %>%
    tbl("user_statistics") %>%
    filter(user_id == user_requested) %>%
    collect()

  # generate object to return
  user_statistics

  } else {
    res$status <- 403 # Forbidden
    return(list(error = "Read access forbidden."))
  }
}


#* @tag user
#* request password reset
#' @get /api/user/password/reset/request
function(req, res, email_request = "") {

  # get data from database
  user_table <- pool %>%
      tbl("user") %>%
      collect()

  # first validate email
  if (!is_valid_email(email_request)) {
    res$status <- 400 # Bad Request
    return(list(error = "Invalid Parameter Value Error."))
  } else if (!(email_request %in% user_table$email)) {
    res$status <- 200 # OK
    res <- "Request mail send!" # This is to not enable attacks on userbase
  } else if ((email_request %in% user_table$email)) {
    # transfor to lower case for comparisons
    email_user <- str_to_lower(toString(email_request))

    # get user data from database table
    user_table <- user_table %>%
      mutate(email_lower = str_to_lower(email)) %>%
      filter(email_lower == email_user) %>%
      mutate(hash = toString(md5(paste0(dw$salt, password)))) %>%
      select(user_id, user_name, hash, email)

    # extract user_id by mail
    user_id_from_email <- user_table$user_id

    # request time
    timestamp_request <- Sys.time()
    timestamp_iat <- as.integer(timestamp_request)
    timestamp_exp <- as.integer(timestamp_request) + dw$refresh

    # load secret and convert to raw
    key <- charToRaw(dw$secret)

    # connect to database, put timestamp of request password reset
    hnf1b_db <- dbConnect(RMariaDB::MariaDB(),
      dbname = dw$dbname,
      user = dw$user,
      password = dw$password,
      server = dw$server,
      host = dw$host,
      port = dw$port)

    dbExecute(hnf1b_db,
      paste0("UPDATE user SET password_reset_date = '",
        timestamp_request,
        "' WHERE user_id = ",
        user_id_from_email[1],
        ";"))

    dbDisconnect(hnf1b_db)

    claim <- jwt_claim(user_id = user_table$user_id,
      user_name = user_table$user_name,
      email = user_table$email,
      hash = user_table$hash,
      iat = timestamp_iat,
      exp = timestamp_exp)
    jwt <- jwt_encode_hmac(claim, secret = key)
    reset_url <- paste0(dw$app_url, "/PasswordReset/", jwt)

    # send mail
    res$status <- 200 # OK
    res <- send_noreply_email(c(
       "We received a password reset for your account",
       "at hnf1b.org. Use this link to reset:",
       reset_url),
       "Your password reset request for hnf1b.org",
       user_table$email
      )
  } else {
    res$status <- 401 # Unauthorized
    return(list(error = "Error or unauthorized."))
  }
}


#* @tag user
#* does password reset
#' @get /api/user/password/reset/change
function(req, res, new_pass_1 = "", new_pass_2 = "") {

  # load jwt from header
  jwt <- str_remove(req$HTTP_AUTHORIZATION, "Bearer ")

  # load secret and convert to raw
  key <- charToRaw(dw$secret)

  user_jwt <- jwt_decode_hmac(jwt, secret = key)
  user_jwt$token_expired <- (user_jwt$exp < as.numeric(Sys.time()))

  if (is.null(jwt) || user_jwt$token_expired) {
    res$status <- 401 # Unauthorized
    return(list(error = "Reset token expired."))
  } else {
    #get user data from database table
    user_table <- pool %>%
      tbl("user") %>%
      collect() %>%
      filter(user_id == user_jwt$user_id) %>%
      mutate(hash = toString(md5(paste0(dw$salt, password)))) %>%
      mutate(timestamp_iat = as.integer(password_reset_date) - dw$refresh) %>%
      mutate(timestamp_exp = as.integer(password_reset_date)) %>%
      select(user_id, user_name, hash, email, timestamp_iat, timestamp_exp)

    # compute JWT check
    claim_check <- jwt_claim(user_id = user_table$user_id,
      user_name = user_table$user_name,
      email = user_table$email,
      hash = user_table$hash,
      iat = user_table$timestamp_iat,
      exp = user_table$timestamp_exp)

    jwt_check <- jwt_encode_hmac(claim_check, secret = key)
    jwt_match <- (jwt == jwt_check)

    # check if passwords match and the new password satisfies minimal criteria
    # TODO: change this into a function
    new_pass_match_and_valid <- (new_pass_1 == new_pass_2) &&
      nchar(new_pass_1) > 7 &&
      grepl("[a-z]", new_pass_1) &&
      grepl("[A-Z]", new_pass_1) &&
      grepl("\\d", new_pass_1) &&
      grepl("[!@#$%^&*]", new_pass_1)

    # connect to database and change password
    # if criteria fullfilled, remove time to invalidate JWT
    if (jwt_match && new_pass_match_and_valid) {
      # connect to database, put approval for user application then disconnect
    hnf1b_db <- dbConnect(RMariaDB::MariaDB(),
      dbname = dw$dbname,
      user = dw$user,
      password = dw$password,
      server = dw$server,
      host = dw$host,
      port = dw$port)

      dbExecute(hnf1b_db,
        paste0("UPDATE user SET password = '",
          new_pass_1,
          "' WHERE user_id = ",
          user_jwt$user_id,
          ";"))

      dbExecute(hnf1b_db,
        paste0("UPDATE user SET password_reset_date = NULL WHERE user_id = ",
          user_jwt$user_id,
          ";"))

      dbDisconnect(hnf1b_db)

      res$status <- 201 # Created
      return(list(message = "Password successfully changed."))
    } else {
      res$status <- 409 # Conflict
      return(list(error = "Password or JWT input problem."))
    }
  }
}

##-------------------------------------------------------------------##



##-------------------------------------------------------------------##
## Authentication section

#* @tag authentication
#* manages user signup
#* @serializer json list(na="string")
#' @post /api/auth/signup
function() {
  ## get json string from arguments body
  signup_data <- req$argsBody$signup_json

  ## convert to tibble and check values for database
  user <- tibble::as_tibble(fromJSON(signup_data)) %>%
      mutate(terms_agreed = case_when(
        terms_agreed == "accepted" ~ "1",
        terms_agreed != "accepted" ~ "0"
      )) %>%
    select(user_name,
      first_name,
      family_name,
      email,
      orcid,
      comment,
      terms_agreed)

  ## perform input validation
  input_validation <- pivot_longer(user, cols = everything()) %>%
      mutate(valid = case_when(
        name == "user_name" ~ (nchar(value) >= 5 & nchar(value) <= 20),
        name == "first_name" ~ (nchar(value) >= 2 & nchar(value) <= 50),
        name == "family_name" ~ (nchar(value) >= 2 & nchar(value) <= 50),
        name == "email" ~ str_detect(value, regex(".+@.+\\..+", dotall = TRUE)),
        name == "orcid" ~ str_detect(value,
          regex("^(([0-9]{4})-){3}[0-9]{3}[0-9X]$",
          dotall = TRUE)),
        name == "comment" ~ (nchar(value) >= 10 & nchar(value) <= 250),
        name == "terms_agreed" ~ (value == "1")
      )) %>%
      mutate(all = "1") %>%
      select(all, valid) %>%
      group_by(all) %>%
      summarise(valid = as.logical(prod(valid))) %>%
      ungroup() %>%
      select(valid)

  ## if valid submit the data to the database
  if (input_validation$valid) {

    # connect to database
    hnf1b_db <- dbConnect(RMariaDB::MariaDB(),
      dbname = dw$dbname,
      user = dw$user,
      password = dw$password,
      server = dw$server,
      host = dw$host,
      port = dw$port)

    db_transaction_response <- dbAppendTable(hnf1b_db, "user", user)
    dbDisconnect(hnf1b_db)

    # send mail if data successfully written to database
    if (db_transaction_response == 1) {

      res <- send_noreply_email(c(
        "Your registration request for hnf1b.org has been send to the curators",
        "who will review it soon. Information provided:",
        user),
        "Your registration request to hnf1b.org",
        user$email
        )
    } else {
      res$status <- 500
      res$body <- "User data could not be written to the database."
      res
  }

  } else {
    res$status <- 404
    res$body <- "Please provide valid registration data."
    res
  }
}


#* @tag authentication
#* does user login
## based on "https://github.com/
## jandix/sealr/blob/master/examples/jwt_simple_example.R"
#* @serializer json list(na="string")
#' @get /api/auth/authenticate
function(req, res, user_name, password) {

  check_user <- user_name
  check_pass <- URLdecode(password)

  # load secret and convert to raw
  key <- charToRaw(dw$secret)

  # check if user provided credentials
      if (is.null(check_user) ||
        nchar(check_user) < 5 ||
        nchar(check_user) > 20 ||
        is.null(check_pass) ||
        nchar(check_pass) < 5 ||
        nchar(check_pass) > 50) {
      res$status <- 404
      res$body <- "Please provide valid username and password."
      res
      }

  # connect to database, find user in database and password is correct
  user_filtered <- pool %>%
    tbl("user") %>%
    filter(user_name == check_user & password == check_pass & approved == 1) %>%
    select(-password) %>%
    collect() %>%
    mutate(iat = as.numeric(Sys.time())) %>%
    mutate(exp = as.numeric(Sys.time()) + dw$refresh)

  # return answer depending on user credentials status
  if (nrow(user_filtered) != 1) {
    res$status <- 401
    res$body <- "User or password wrong."
    res
  }

  if (nrow(user_filtered) == 1) {
    claim <- jwt_claim(user_id = user_filtered$user_id,
    user_name = user_filtered$user_name,
    email = user_filtered$email,
    user_role = user_filtered$user_role,
    user_created = user_filtered$created_at,
    abbreviation = user_filtered$abbreviation,
    orcid = user_filtered$orcid,
    iat = user_filtered$iat,
    exp = user_filtered$exp)

    jwt <- jwt_encode_hmac(claim, secret = key)
    jwt
  }
}


#* @tag authentication
#* does user authentication
#* @serializer json list(na="string")
#' @get /api/auth/signin
function(req, res) {
  # load secret and convert to raw
  key <- charToRaw(dw$secret)

  # load jwt from header
  jwt <- str_remove(req$HTTP_AUTHORIZATION, "Bearer ")

  user <- jwt_decode_hmac(jwt, secret = key)
  user$token_expired <- (user$exp < as.numeric(Sys.time()))

  if (is.null(jwt) || user$token_expired) {
    res$status <- 401 # Unauthorized
    return(list(error = "Authentication not successful."))
  } else {
    return(list(user_id = user$user_id,
      user_name = user$user_name,
      email = user$email,
      user_role = user$user_role,
      user_created = user$user_created,
      abbreviation = user$abbreviation,
      orcid = user$orcid,
      exp = user$exp))
  }
}


#* @tag authentication
#* does authentication refresh
#* @serializer json list(na="string")
#' @get /api/auth/refresh
function(req, res) {
  # load secret and convert to raw
  key <- charToRaw(dw$secret)

  # load jwt from header
  jwt <- str_remove(req$HTTP_AUTHORIZATION, "Bearer ")

  user <- jwt_decode_hmac(jwt, secret = key)
  user$token_expired <- (user$exp < as.numeric(Sys.time()))

  if (is.null(jwt) || user$token_expired) {
    res$status <- 401 # Unauthorized
    return(list(error = "Authentication not successful."))
  } else {
    claim <- jwt_claim(user_id = user$user_id,
      user_name = user$user_name,
      email = user$email,
      user_role = user$user_role,
      user_created = user$user_created,
      abbreviation = user$abbreviation,
      orcid = user$orcid,
      iat = as.numeric(Sys.time()),
      exp = as.numeric(Sys.time()) + dw$refresh)

    jwt <- jwt_encode_hmac(claim, secret = key)
    jwt
  }
}

##Authentication section
##-------------------------------------------------------------------##
