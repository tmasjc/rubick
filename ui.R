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
    
    fluidPage(
        useShinyjs(),
        materialSwitch(inputId = "ctrl",
                       label = tags$small("隐藏控制板"),
                       status = "info"), 
        column(12, dataTableOutput("tbl", height = "640px")),
        hidden(
            absolutePanel(
                id = "controls",
                class = "well",
                fixed = TRUE,
                draggable = TRUE,
                top = 200,
                left = 20,
                right = "auto",
                bottom = "auto",
                width = 350,
                height = "auto",
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
                tags$small("注: 只显示部分结果, 全量数据请点击下载."),
                tags$br(), tags$br(),
                downloadLink("downloadRes", label = tags$strong("下载数据", icon("download")))
            )
        )
        
    )
)
