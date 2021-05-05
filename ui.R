function(request) {
    
    # read global setting here
    globe <- config::get()
    
    fluidPage(
        
        tags$head(
            tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
        ),
        
        use_waiter(), # loading screen dependencies
        
        titlePanel(globe$title),
        tags$h4(globe$subtitle),
        tags$hr(),
        theme = shinytheme("yeti"),
        
        fluidPage(
            sidebarLayout(
                sidebarPanel(
                    id = "controls",
                    class = "well",
                    left = 20,
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
                    tags$small("为了优化计算性能，右侧只会显示部分结果。"),
                    tags$br(), tags$br(),
                    downloadLink("downloadRes", label = tags$strong("点击下载全量数据", icon("download")))
                ),
                mainPanel(
                    column(12, dataTableOutput("tbl", height = "640px"))
                )
                
            )
        )
    )
}