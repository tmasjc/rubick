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
        
        # which type of connection?
        if (loc()['type'] == "mysql") {
            conn <- est_mysql_conn(globe, loc())
            
        } else if (loc()['type'] == "hive") {
            conn <- est_hive_conn(globe, loc())
            
        } else {
            stop("Check type declaration.")
        }
        
        # 'query' the variable name is fixed!
        query <- query()
        
        # evaluate interpolation 
        # let error displayed to output
        q     <- eval(parse_expr(meta()))
        message("Query: ", q)
        
        # fetch data
        res   <- DBI::dbGetQuery(conn, q)
        
        DBI::dbDisconnect(conn)
        message("Close connection.")
        
        return(res)
        
    })
    
    output$tbl <- renderDataTable({
        
        req(res())
        
        datatable(
            data          = head(res(), 20),
            options       = list(dom = 'tip'), 
            class         = 'cell-border stripe',
            fillContainer = TRUE,
            rownames      = FALSE
        )
        
    })
    
    
}
