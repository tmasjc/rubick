ui <- fluidPage(
    
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    ),
    
    use_waiter(), # loading screen dependencies
    
    titlePanel("R U B I C K"),
    tags$hr(),
    theme = shinytheme("yeti"),
    
    sidebarLayout(
        sidebarPanel(
            selectizeInput(
                inputId = "form",
                label   = tags$h4("可选项"),
                choices = "",
                width   = "100%"
            ),
            uiOutput("variables"),
            textInput("token", "Token", width = "60%"),
            actionButton(
                inputId = "run",
                label   = "Run",
                icon    = icon("circle-notch"),
                width   = "100%"
            ), 
            width = 3
        ),
        mainPanel(
            tags$h4("Result"),
            column(12, dataTableOutput("tbl", height = "480px")), 
            tags$h4("Query"),
            verbatimTextOutput("print_query"),
            width = 8
        ), 
        position = "right"
    )
)