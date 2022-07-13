library(plumber)

Sys.setenv(API_CONFIG = "hnf1b_db_local")

setwd("C:/development/HNF1B-db/api")

root <- pr("api_plumber.R") %>%
        pr_set_api_spec(function(spec) {
        spec$components$securitySchemes$bearerAuth$type <- "http"
        spec$components$securitySchemes$bearerAuth$scheme <- "bearer"
        spec$components$securitySchemes$bearerAuth$bearerFormat <- "JWT"
        spec$security[[1]]$bearerAuth <- ""
        spec
        })  %>%
        pr_run(host = "0.0.0.0", port = 7779)