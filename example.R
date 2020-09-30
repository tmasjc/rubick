library(tidyverse)
library(DBI)
library(dbplyr)
library(config)

# global parameters, including username and password
glo <- config::get()

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

# which specfic config to load (local)
loc <- config::get(config = glo[["example1"]])

# establish connection to db
conn <- est_conn(glo, loc)

# determines which SQL file
query <- read_file(str_glue("{ glo$src }/{ loc$file }"))
SQL(query)

# parse variables from SQL
vars <- query %>%
    str_extract_all(pattern = "\\?\\w+", simplify = TRUE) %>%
    map_chr( ~ str_remove(., pattern = "^\\?"))

# bind variables to interpolate func to form complete query string
# unevaluated expression
meta <- 
    str_glue(
        "sqlInterpolate(conn = conn, \\
             sql = query, \\
             {vars[1]} = Sys.Date() - 7, \\
             {vars[2]} = Sys.Date() - 1)"
    )

# evaluate now
q <- eval(parse(text = meta))

DBI::dbGetQuery(conn, q) %>% head()

DBI::dbDisconnect(conn)
