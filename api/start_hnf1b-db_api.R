library(plumber)

setwd("/hnf1b_api_volume")

root <- pr("hnf1b-db_plumber.R") %>%
        pr_run(host = "0.0.0.0", port = 7779) %>%
		pr_hook("exit", function(){ poolClose(pool) })