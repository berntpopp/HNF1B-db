library(plumber)

Sys.setenv(API_CONFIG = "hnf1b_db_local")

setwd("C:/development/HNF1B-db/api")

root <- pr("api_plumber.R") %>%
        pr_run(host = "0.0.0.0", port = 7779)