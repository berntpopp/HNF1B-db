# generate sort expressions to parse
generate_sort_expressions <- function(sort_string, unique_id = "entity_id") {

  # split the sort input by comma and compute directions based on presence of + or - in front of the string
  sort_tibble <- as_tibble(str_split(str_replace_all(sort_string, fixed(" "), ""), ",")[[1]]) %>%
        select(column = value) %>%
        mutate(direction = case_when(
            str_sub(column, 1, 1) == "+" ~ "asc",
            str_sub(column, 1, 1) == "-" ~ "desc",
            TRUE ~ "asc",
        )) %>%
        mutate(column = case_when(
            str_sub(column, 1, 1) == "+" ~ str_sub(column, 2, -1),
            str_sub(column, 1, 1) == "-" ~ str_sub(column, 2, -1),
            TRUE ~ column,
        )) %>%
        mutate(exprs = case_when(
            direction == "asc" ~ column,
            direction == "desc" ~ paste0("desc(", column, ")"),
        )) %>%
    unique %>%
    group_by(column) %>%
    mutate(count = n())

    sort_list <- sort_tibble$exprs

    # and check if entity_idis in the resulting list, if not append to the list for unique sorting
  if ( !(unique_id %in% sort_list | paste0("desc(", unique_id, ")") %in% sort_list) ){
    sort_list <- append(sort_list, unique_id)
  }

    return(sort_list)
}


# generate filter expressions to parse
# semantics according to https://www.jsonapi.net/usage/reading/filtering.html
# currently only implemented "Equality" and "Contains text"
# need to implement error handling
# need to implement whether the respective columns exist
# need to implement allowed Operations as input argument
generate_filter_expressions <- function(filter_string, operations_allowed = "equals,contains,any") {
  # define supported operations
  operations_supported <- "equals,contains,any,and,or,not" %>%
    str_split(pattern=",", simplify=TRUE) %>%
    str_replace_all(" ", "") %>%
    unique()

  # define supported logic
  logic_supported <- "and,or,not" %>%
    str_split(pattern=",", simplify=TRUE) %>%
    str_replace_all(" ", "") %>%
    unique()

  # transform submitted operations to list
  operations_allowed <- URLdecode(operations_allowed) %>%
    str_split(pattern=",", simplify=TRUE) %>%
    str_replace_all(" ", "") %>%
    unique()

  filter_string <- URLdecode(filter_string) %>%
    str_trim()

  logical_operator <- stringr::str_extract(string = filter_string, pattern = ".+?\\(") %>%
    stringr::str_remove_all("\\(")

  if ( logical_operator %in% logic_supported ){
    filter_string <- filter_string %>%
      stringr::str_extract(pattern = "(?<=\\().*(?=\\))")
  } else {
    logical_operator <- "and"
  }

    # check if requested operations are supported, if not through error
  if ( all(operations_allowed %in% operations_supported) ) {
    if (filter_string != "") {
      # 
      filter_tibble <- as_tibble(str_split(str_squish(filter_string), "\\),")[[1]]) %>%
        separate(value, c("logic", "column_value"), sep = "\\(") %>%
        separate(column_value, c("column", "filter_value"), sep = "\\,", extra = "merge") %>%
        mutate(filter_value = str_remove_all(filter_value, "'|\\)")) %>%
        mutate(exprs = case_when(
          column == "any" & logic == "contains" ~ paste0("if_any(everything(), ~str_detect(.x, '", filter_value, "'))"),
          column == "all" & logic == "contains" ~ paste0("if_all(everything(), ~str_detect(.x, '", filter_value, "'))"),
          !(column %in% c("all", "any")) & logic == "contains" ~ paste0("str_detect(", column, ", '", filter_value, "')"),
          column == "any" & logic == "equals" ~ paste0("if_any(everything(), ~str_detect(.x, '^", filter_value, "$'))"),
          column == "all" & logic == "equals" ~ paste0("if_all(everything(), ~str_detect(.x, '^", filter_value, "$'))"),
          !(column %in% c("all", "any")) & logic == "equals" ~ paste0("str_detect(", column, ", '^", filter_value, "$')"),
          column == "any" & logic == "any" ~ paste0("if_any(everything(), ~str_detect(.x, ", str_replace_all(paste0("'^", filter_value, "$')"), pattern = "\\,", replacement = "$|^"), ")"),
          column == "all" & logic == "any" ~ paste0("if_all(everything(), ~str_detect(.x, ", str_replace_all(paste0("'^", filter_value, "$')"), pattern = "\\,", replacement = "$|^"), ")"),
          !(column %in% c("all", "any")) & logic == "any" ~ paste0("str_detect(", column, ", ", str_replace_all(paste0("'^", filter_value, "$')"), pattern = "\\,", replacement = "$|^")),
        )) %>%
        filter(logic %in% operations_allowed) %>%
        filter(!is.na(exprs))

      filter_list <- filter_tibble$exprs

      # compute filter string based on input logic
      if ( logical_operator == "and" ) {
        filter_expression <- str_c(filter_list, collapse = " & ")
      } else if ( logical_operator == "or" ) {
        filter_expression <- str_c(filter_list, collapse = " | ")
      } else if ( logical_operator == "not" ) {
        filter_expression <- paste0("!( ", str_c(filter_list, collapse = " | "), " )")
      }

      return(filter_expression)
    } else {
      return(filter_string)
    }
  } else {
    stop("Some requested operations are not supported.")
  }
}


# select requested fields from tibble
select_tibble_fields <- function(selection_tibble, fields_requested, unique_id = "entity_id") {

  # get column names from selection_tibble
  tibble_colnames <- colnames(selection_tibble)

  # check if fields_requested is empty string, if so assign tibble_colnames to it, else 
  # split the fields_requested input by comma
  if ( fields_requested != "" ){
    fields_requested <- str_split(str_replace_all(fields_requested, fixed(" "), ""), ",")[[1]]
  } else {
    fields_requested <- tibble_colnames
  }

    # check if unique_id variable is in the column names, if not prepend to the list for unique sorting
  if ( !(unique_id %in% fields_requested) ){
    fields_requested <- purrr::prepend(fields_requested, unique_id)
    fields_requested <- Filter(function(x) !identical("",x), fields_requested)
  }
  
    # check if requested column names exist in tibble, if error
  if ( all(fields_requested %in% tibble_colnames) ){
    selection_tibble <- selection_tibble %>%
    select(all_of(fields_requested))
  } else {
    stop("Some requested fields are not in the column names.")
  }

    return(selection_tibble)
}


# generate cursor pagination information from a tibble
generate_cursor_pagination_info <- function(pagination_tibble, page_size = "all", page_after = 0, pagination_identifier = "entity_id") {

  # get number of rows in filtered ndd_entity_view
  pagination_tibble_rows <- (pagination_tibble %>%
    summarise(n = n()))$n

  # check if page_size is either "all" or a valid integer and convert or assign values accordingly
  if ( page_size == "all" ){
    page_after <- 0
    page_size <- pagination_tibble_rows
    page_count <- ceiling(pagination_tibble_rows/page_size)
  } else if ( is.numeric(as.integer(page_size)) )
  {
    page_size <- as.integer(page_size)
    page_count <- ceiling(pagination_tibble_rows/page_size)
  } else
  {
    stop("Page size provided is not numeric or all.")
  }

  # find the current row of the requested page_after entry
  page_after_row <- (pagination_tibble %>%
    mutate(row = row_number()) %>%
    filter(!!sym(pagination_identifier) == page_after)
    )$row

  if ( length(page_after_row) == 0 ){
    page_after_row <- 0
    page_after_row_next <- ( pagination_tibble %>%
      filter(row_number() == page_after_row + page_size + 1) %>%
      select(!!sym(pagination_identifier)) )[[1]]
  } else {
    page_after_row_next <- ( pagination_tibble %>%
      filter(row_number() == page_after_row + page_size) %>%
      select(!!sym(pagination_identifier)) )[[1]]
  }

  # find next and prev item row
  page_after_row_prev <- ( pagination_tibble %>%
    filter(row_number() == page_after_row - page_size) %>%
      select(!!sym(pagination_identifier)) )[[1]]
  page_after_row_last <- ( pagination_tibble %>%
    filter(row_number() == page_size * (page_count - 1) ) %>%
      select(!!sym(pagination_identifier)) )[[1]]
    
  # filter by row
  pagination_tibble <- pagination_tibble %>%
    filter(row_number() > page_after_row & row_number() <= page_after_row + page_size)

  # generate links for self, next and prev pages
  self <- paste0("&page[after]=", page_after, "&page[size]=", page_size)
  if ( length(page_after_row_prev) == 0 ){
    prev <- "null"
  } else
  {
    prev <- paste0("&page[after]=", page_after_row_prev, "&page[size]=", page_size)
  }
  
  if ( length(page_after_row_next) == 0 ){
    `next` <- "null"
  } else
  {
    `next` <- paste0("&page[after]=", page_after_row_next, "&page[size]=", page_size)
  }
  
  if ( length(page_after_row_last) == 0 ){
    last <- "null"
  } else
  {
    last <- paste0("&page[after]=", page_after_row_last, "&page[size]=", page_size)
  }

  # generate links object
  links <- as_tibble(list("prev" = prev, 
    "self" = self, 
    "next" = `next`, 
    "last" = last))
  
  # generate meta object
  meta <- as_tibble(list("perPage" = page_size, 
    "currentPage" = ceiling((page_after_row+1)/page_size), 
    "totalPages" = page_count, 
    "prevItemID" = (if (length(page_after_row_prev) == 0) {"null"} else {page_after_row_prev}), 
    "currentItemID" = page_after, 
    "nextItemID" = (if (length(page_after_row_next) == 0) {"null"} else {page_after_row_next}), 
    "lastItemID" = (if (length(page_after_row_last) == 0) {"null"} else {page_after_row_last}), 
    "totalItems" = pagination_tibble_rows)
  )

  # generate return list
  return_data <- list(links = links, meta = meta, data = pagination_tibble)
  
  return(return_data)
}