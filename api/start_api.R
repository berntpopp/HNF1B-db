library(plumber)

Sys.setenv(API_CONFIG = "hnf1b_db")

setwd("/hnf1b_api_volume")

root <- pr("api_plumber.R") %>%
        pr_set_api_spec(function(spec) {
        spec$components$securitySchemes$bearerAuth$type <- "http"
        spec$components$securitySchemes$bearerAuth$scheme <- "bearer"
        spec$components$securitySchemes$bearerAuth$bearerFormat <- "JWT"
        spec$security[[1]]$bearerAuth <- ""
        spec
        })  %>%
        pr_run(host = "0.0.0.0", port = 7779)