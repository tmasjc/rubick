library(tidyverse)
library(shiny)
library(shinythemes)
library(DBI)
library(dbplyr)
library(config)
library(rlang)
library(DT)

ui <- fluidPage(
    
    titlePanel("R U B I C K"),
    tags$hr(),
    theme = shinytheme("yeti"),
    
    sidebarLayout(
        sidebarPanel(
            selectizeInput(
                inputId = "form",
                label   = tags$h4("Forms"),
                choices = "",
                width   = "100%"
            ),
            uiOutput("variables"),
            actionButton(
                inputId = "run",
                label   = "Run",
                icon    = icon("circle-notch"),
                width   = "100%"
            ), 
            width = 2
        ),
        mainPanel(
            verbatimTextOutput("print_query"),
            dataTableOutput("tbl"), 
            width = 8
        )
    )
)

# extract declared forms from config.yml
parse_forms <- function(l) {
    ind <- which(stringr::str_detect(names(l), "^form"))
    unlist(l[ind], use.names = FALSE)
}

# locate appropriate driver
driver <- function(drv) {
    x <- tolower(drv)
    if (x == "mysql") {
        return(RMySQL::MySQL())
    }
}

est_conn <- function(g, l) {
    
    # g for global, x for local
    DBI::dbConnect(
        user     = g[["username"]],
        password = g[["password"]],
        host     = l[["db_host"]],
        port     = l[["db_port"]],
        dbname   = l[["db_name"]],
        drv      = driver(l[["drv"]])
    )
}

server <- function(input, output, session) {
    
    # read global setting here
    globe <- config::get()
    
    # update forms 
    forms <- parse_forms(globe)
    updateSelectizeInput(session, "form", choices = forms, selected = "")
    
    # when user selects, read SQL file accordingly
    loc   <- reactive({
        req(input$form)
        config::get(config = tolower(input$form))
    })
    
    # this is our raw query to database
    query <- reactive({
        
        tryCatch(
            read_file(str_glue("{ globe$src }/{ loc()$file }")),
            # in case file not found
            error = function(e) {
                return("")
            }
        )
        
    })
    
    # extract variables here
    vars  <- reactive({
        
        query() %>%
            str_extract_all("\\?\\w+", simplify = TRUE) %>%
            map_chr(~ str_remove(., "\\?"))
        
    })
    
    # interpolate query here
    meta <- reactive({
        
        req(vars())
        
        # parse user's inputs here
        inputs <- paste0("input$", vars()) %>% 
            map(~ eval(parse_expr(.x)))
        
        # collpase 'abc = input$abc'
        v <- vars() %>% 
            map2(inputs, ~ str_glue("{.x} = {.y}")) %>% 
            paste(collapse = ", ")
        
        str_glue("sqlInterpolate(conn, query, {v})")
        
    })
    
    # use metaprogramming to render UI
    output$variables <- renderUI({
    
        exprs <-
            map(vars(), ~ str_glue("textInput('{.x}', '{.x}', width = '100%')"))
        
        tagList(map(exprs, ~ eval(parse_expr(.x))))
        
    })
    
    # preview meta query
    output$print_query <- renderText({
        query()
    })
    
    res <- eventReactive(input$run, {
        
        message("Ready to establish connection.")
        
        conn  <- est_conn(globe, loc())
        
        # 'query' the variable name is fixed!
        query <- query()
        
        # evaluate interpolation 
        q     <- eval(parse_expr(meta()))
        
        # fetch data
        res   <- DBI::dbGetQuery(conn, q)
        
        DBI::dbDisconnect(conn)
        message("Close connection.")
        return(res)
        
    })
    
    output$tbl <- renderDataTable({
        
        req(meta())
        
        datatable(
            head(res(), 20),
            options   = list(dom = 'tip'), 
            rownames  = FALSE
        )
        
    })
    
    
}

shinyApp(ui, server)
