library(tidyverse)
library(shiny)
library(shinythemes)
library(DBI)
library(odbc)
library(dbplyr)
library(config)
library(rlang)
library(DT)
library(waiter)

# extract declared forms from config.yml
parse_forms <- function(l) {
    ind <- which(stringr::str_detect(names(l), "^form"))
    unlist(l[ind], use.names = FALSE)
}

# establish to specified connection
est_mysql_conn <- function(db) {
    DBI::dbConnect(
        drv      = db[["driver"]],
        host     = db[["host"]],
        port     = db[["port"]],
        user     = db[["username"]],
        password = db[["password"]],
        dbname   = db[["dbname"]]
    )
}

est_hive_conn <- function(db) {
    DBI::dbConnect(
        odbc::odbc(),
        Driver   = db[['driver']],
        Host     = db[["host"]],
        Port     = db[["port"]],
        UID      = db[["username"]],
        PWD      = db[["passwors"]]
    )
}

# customize loading screen
waiting_screen <- tagList(
    spin_dual_circle(),
    h4("请稍等片刻，拉比克正在为大人您服务 ٩(◕‿◕｡)۶ ")
) 