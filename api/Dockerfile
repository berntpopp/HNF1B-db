FROM rocker/tidyverse:latest
## Install Java
RUN apt-get update && apt-get install -y \
default-jdk \
## used to build rJava and other packages
libbz2-dev \
libicu-dev \
liblzma-dev \
libsodium-dev
RUN Rscript -e 'install.packages(c("Rcpp", "plumber", "DBI", "RMariaDB", "jsonlite", "config", "jose", "RCurl", "stringdist", "xlsx", "easyPubMed", "rvest", "lubridate", "pool", "memoise", "coop", "cowplot", "timetk"), repos="https://cloud.r-project.org")'