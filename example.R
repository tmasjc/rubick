library(tidyverse)
library(DBI)
library(dbplyr)
library(config)

cnf <- config::get()

est_conn <- function(g, l) {
    # g for global, x for local
    DBI::dbConnect(
        drv      = RMySQL::MySQL(),
        user     = g[["username"]],
        password = g[["password"]],
        host     = l[["db_host"]],
        port     = l[["db_port"]],
        dbname   = l[["db_name"]]
    )
}

# which config to load
wic <- config::get(config = cnf[["d1"]])

# establish connection to db
conn <- est_conn(cnf, wic)

query <- read_file(str_glue("{ cnf$src }/{ wic$file }"))

x1 = "date_start"; x2 = "date_end";

# bind variables to interpolate func to form complete query string
# unevaluated expression
meta <- 
    str_glue("sqlInterpolate(conn = conn, \\
             sql = query, \\
             {x1} = Sys.Date() - 7, \\
             {x2} = Sys.Date() - 1)")

q <- eval(parse(text = meta))

DBI::dbGetQuery(conn, q)

DBI::dbDisconnect(conn)
