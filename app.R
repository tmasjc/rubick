library(tidyverse)
library(shiny)
library(shinythemes)
library(DBI)
library(dbplyr)
library(config)
library(rlang)

ui <- fluidPage(
    
    titlePanel("R U B I C K"),
    tags$hr(),
    theme = shinytheme("yeti"),
    
    column(
        width  = 4,
        offset = 4,
        selectizeInput(
            inputId = "form",
            label   = tags$h4("Forms"),
            choices = "",
            width   = "40%"
        ),
        uiOutput("variables"),
        verbatimTextOutput("print_query")
        # actionButton("go", label = "GO", icon = icon("circle-notch"))
    )
)

# extract declared forms from config.yml
parse_forms <- function(l) {
    ind <- which(stringr::str_detect(names(l), "^form"))
    unlist(l[ind], use.names = FALSE)
}

est_conn <- function(g, l, driver) {
    # g for global, x for local
    DBI::dbConnect(
        drv      = driver,
        user     = g[["username"]],
        password = g[["password"]],
        host     = l[["db_host"]],
        port     = l[["db_port"]],
        dbname   = l[["db_name"]]
    )
}

server <- function(input, output, session) {
    
    # read global setting here
    globe <- config::get()
    
    # update forms 
    forms <- parse_forms(globe)
    updateSelectizeInput(session, "form", choices = forms, selected = "")
    
    query <- reactive({
        
        # when user selects, read SQL file accordingly
        loc   <- config::get(config = tolower(input$form))
        
        tryCatch(
            read_file(str_glue("{ globe$src }/{ loc$file }")),
            # in case file not found
            error = function(e) {
                return("")
            }
        )
    })
    
    # render variables from chosen config
    output$variables <- renderUI({
        
        req(input$form)
        
        # extract variables here
        vars  <- query() %>%
            str_extract_all("\\?\\w+", simplify = TRUE) %>%
            map_chr(~ str_remove(., "\\?"))
        
        # use metaprogramming to render UI
        exprs <- map(vars, ~ str_glue("textInput('{.x}', '{.x}')"))
        tagList(map(exprs, ~ eval(parse_expr(.x))))
        
    })
    
    # preview query
    output$print_query <- renderText({
        query()
    })
    
    
}

shinyApp(ui, server)