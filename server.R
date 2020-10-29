server <- function(input, output, session) {
    
    # read global setting here
    globe <- config::get()
    
    # create loading screen obj
    w <- Waiter$new(html = waiting_screen, color = "black")
    
    # update forms 
    forms <- parse_forms(globe$config)
    names(forms) <- map_chr(forms, ~ get_form_name(.x))
    
    # assign group to form
    grps <- map_chr(forms, ~ get_form_group(.x))
    form_choices <- map(unique(grps), ~ forms[which(grps == .x)])
    names(form_choices) <- unique(grps)
    
    # populate form selection
    updateSelectizeInput(session, "form", choices = form_choices, selected = "")
    
    observeEvent(input$ctrl, {
        toggle(id = 'controls')
    })
    
    # when user selects, read SQL file accordingly
    loc <- reactive({
        req(input$form)
        config::get(config = tolower(input$form))
    })
    
    # this is our raw query to database
    query <- reactive({
        
        tryCatch(
            read_file(str_glue("{ globe$source }/{ loc()$file }")),
            # in case file not found
            error = function(e) {
                return("")
            }
        )
        
    })
    
    # extract variables here
    vars <- reactive({
        
        req(input$form)
        
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
            map2(inputs, ~ str_glue("{.x} = SQL({.y})")) %>% 
            paste(collapse = ", ")
        
        #message(str_glue("sqlInterpolate(conn, query, {v})"))
        str_glue("sqlInterpolate(conn, query, {v})")
        
    })
    
    output$description <- renderUI({
        
        req(input$form)
        
        tagList(
            tags$small(id = "desc", paste0("::", loc()[['description']])),
            tags$p("")
        )
    })
    
    # use metaprogramming to render UI
    output$variables <- renderUI({
    
        exprs <-
            map(vars(), ~ str_glue("textInput('{.x}', '{.x}', width = '100%')"))
        
        tagList(map(exprs, ~ eval(parse_expr(.x))))
        
    })
    
    # preview meta query
    output$print_query <- renderText({
        
        req(input$form)
        
        if (query() == "") {
            stop("File not found. Check config.")
        }
        
        query()
    })
    
    # this is our core function
    res <- eventReactive(input$run, {
        
        req(input$form)
        
        # check if token matches
        if (!is.null(loc()[['token']])) {
            validate_token(input$token, loc()[['token']])
        }
        message("Ready to establish connection.")
        
        w$show()
        
        # which type of connection?
        if (is.null(loc()[['origin']])) {
            w$hide()
            stop("Origin not set. Check config.")
        }
        db <- config::get(
            config = loc()[['origin']], 
            file   = globe$database
        )
        
        if (db['type'] == "mysql") {
            conn <- est_mysql_conn(db)
            
        } else if (db['type'] == "hive") {
            conn <- est_hive_conn(db)
            
        } else {
            w$hide()
            stop("Database type not found. Check config.")
        }
        message(DBI::dbGetInfo(conn))
        
        # 'query' the variable name is fixed!
        query <- query()
        
        # evaluate interpolation 
        # let error displayed to output
        tryCatch(
            q <- eval(parse_expr(meta())),
            error = function(e) {
                DBI::dbDisconnect(conn)
                w$hide()
                stop("Failed to parse query. Check arguments.")
            }
        )
        
        # fetch data
        tryCatch(
            res <- DBI::dbGetQuery(conn, q),
            error = function(e) {
                DBI::dbDisconnect(conn)
                w$hide()
                stop("Failed to fetch data.")
            }
        )
        
        DBI::dbDisconnect(conn)
        message("Close connection.")
        
        w$hide()
        
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
    
    output$downloadRes <- downloadHandler(
        filename = function() {
            paste(input$form, "-", Sys.Date(), ".csv", sep = "")
        },
        content <- function(f) {
            write_excel_csv(res(), f)
        }
    )
    
    
}
