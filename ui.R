# read global setting here
globe <- config::get()

ui <- fluidPage(
    
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    ),
    
    use_waiter(), # loading screen dependencies
    
    titlePanel(globe$title),
    tags$h4(globe$subtitle),
    tags$hr(),
    theme = shinytheme("yeti"),
    
    sidebarLayout(
        sidebarPanel(
            selectizeInput(
                inputId = "form",
                label   = tags$h4("Options 可选项"),
                choices = "",
                width   = "100%"
            ),
            uiOutput("description"),
            uiOutput("variables"),
            textInput("token", "Token 秘钥", width = "60%"),
            actionButton(
                inputId = "run",
                label   = "Run",
                icon    = icon("circle-notch"),
                width   = "100%"
            ),
            tags$hr(),
            downloadLink("downloadRes", label = "点击下载数据"),
            width = 3
        ),
        mainPanel(
            tags$h5("Preview 结果预览"),
            column(12, dataTableOutput("tbl", height = "640px")), 
            # tags$h5("Query 查询语句"),
            # verbatimTextOutput("print_query"),
            width = 8
        ), 
        position = "right"
    )
)