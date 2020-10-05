library(tidyverse)
library(shiny)
library(shinythemes)
library(dbplyr)
library(config)

ui <- fluidPage(
    
    titlePanel("R U B I C K"),
    theme = shinytheme("spacelab"),
    
    sidebarLayout(
        
        sidebarPanel(
            selectizeInput(
                inputId = "form",
                label   = "Forms",
                choices = "",
                width   = "80%"
            ),
            uiOutput("variables")
        ),
        
        mainPanel(
            
        )
    )
)

# extract declared forms from config.yml
parse_forms <- function(l) {
    ind <- which(stringr::str_detect(names(l), "^form"))
    unlist(l[ind], use.names = FALSE)
}

server <- function(input, output, session) {
    
    # read global setting here
    globe <- config::get()
    forms <- parse_forms(globe)
    
    # update forms 
    updateSelectizeInput(session, "form", choices = forms, selected = "")
    
    # render variables from chosen config
    output$variables <- renderUI({
        
        req(input$form)
        
        # when user selects, read SQL file accordingly
        loc   <- config::get(config = tolower(input$form))
        
        query <- tryCatch(
            read_file(str_glue("{ globe$src }/{ loc$file }")),
            # in case file not found
            error = function(e) {
                return("")
            }
        )
        
        # extract variables here
        vars  <- query %>%
            str_extract_all("\\?\\w+", simplify = TRUE) %>%
            map_chr(~ str_remove(., "\\?"))
        
        # use metaprogramming to render UI
        exprs <- map(vars, ~ str_glue("textInput('{.x}', '{.x}')"))
        tagList(map(exprs, ~ eval(parse_expr(.x))))
        
    })
}

shinyApp(ui, server)