library(tidyverse)
library(shiny)
library(shinythemes)
library(DBI)
library(odbc)
library(dbplyr)
library(config)
library(rlang)
library(DT)

# extract declared forms from config.yml
parse_forms <- function(l) {
    ind <- which(stringr::str_detect(names(l), "^form"))
    unlist(l[ind], use.names = FALSE)
}

# g for global, x for local
est_mysql_conn <- function(g, l) {
    DBI::dbConnect(
        drv      = g[["mysql_drv"]],
        user     = g[["mysql_user"]],
        password = g[["mysql_pwd"]],
        host     = l[["db_host"]],
        port     = l[["db_port"]],
        dbname   = l[["db_name"]],
    )
}

est_hive_conn <- function(g, l) {
    DBI::dbConnect(
        odbc::odbc(),
        Driver   = g[['hive_drv']],
        UID      = g[["hive_user"]],
        PWD      = g[["hive_pwd"]],
        Host     = l[["db_host"]],
        Port     = l[["db_port"]],
        Schema   = l[["db_name"]]
    )
}
