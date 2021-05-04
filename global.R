library(tidyverse)
library(shiny)
library(shinythemes)
library(DBI)
library(odbc)
library(dbplyr)
library(yaml)
library(config)
library(rlang)
library(DT)
library(waiter)
library(future)
library(promises)
options(shiny.sanitize.errors = FALSE)
options(future.rng.onMisuse = 'ignore')
plan(multisession, workers = 2)

# extract declared forms from config.yml
parse_forms <- function(f) {
    forms <- yaml::read_yaml(file = f)
    names(forms)[-1]
}

# establish to specified connection
est_mysql_conn <- function(db) {
    DBI::dbConnect(
        drv      = RMySQL::MySQL(),
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
waiting_screen <- 
    tagList(
        spin_dual_circle(),
        h4("请稍等片刻，拉比克正在为大人您服务 ٩(◕‿◕｡)۶ ")
    )

validate_token <- function(input, ref) {
    
    if (input != ref) {
        stop("Validation failed. Check token.")
    }
}

get_form_name <- function(form) {
    
    name <- config::get(config = form)[['name']]
    
    if (is.null(name)) {
        return(form)
    }
    
    return(name)
}

get_form_group <- function(form) {
    
    grp <- config::get(config = form)[['group']]
    
    if (is.null(grp)) {
        return("blank")
    }
    
    return(grp)
}
