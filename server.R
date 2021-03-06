 function(input, output, session) {
    
    # read global setting here
    globe <- config::get()
    
    # create loading screen obj
    w <- Waiter$new(html = waiting_screen, color = "black")
    
    # update forms 
    forms <- yaml::read_yaml(file = "config.yml")
    forms <- names(forms)[-1]
    names(forms) <- map_chr(forms, ~ get_form_name(.x))
    
    # assign group to form
    grps <- map_chr(forms, ~ get_form_group(.x))
    form_choices <- map(unique(grps), ~ forms[which(grps == .x)])
    names(form_choices) <- unique(grps)
    
    # populate form selection
    updateSelectizeInput(session, "form", choices = form_choices, selected = "")
    
    # bookmarking via url
    observe({
        reactiveValuesToList(input)
        session$doBookmark()
    })
    onBookmarked(updateQueryString)
    onBookmark(function(state) {
        state$values$form <- input$form
    })
    onRestore(function(state) {
        updateSelectizeInput(session, "form", choices = form_choices, selected = state$values$form)
    })
    setBookmarkExclude("token")
    
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
            map_chr(~ str_remove(., "\\?")) %>% 
            unique()
        
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
        
        str_glue("sqlInterpolate(ANSI(), query, {v})")
        
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
        
        # which type of connection?
        if (is.null(loc()[['origin']])) {
            stop("Origin not set. Check config.")
        }
        db <- config::get(
            config = loc()[['origin']], 
            file   = 'database.yml'
        )
        
        # 'query' the variable name is fixed!
        query <- query()
        
        # evaluate interpolation 
        # let error displayed to output
        tryCatch(
            q <- eval(parse_expr(meta())),
            error = function(e) {
                DBI::dbDisconnect(conn)
                stop("Failed to parse query. Check arguments.")
            }
        )
        # message(q)
        w$show()
        
        # fetch data in a separate process
        future(
            {
                if (db['type'] == "mysql") {
                    conn <- est_mysql_conn(db)
                } else if (db['type'] == "hive") {
                    conn <- est_hive_conn(db)
                } else {
                    stop("Database type not found.")
                }
                message(DBI::dbGetInfo(conn, "host"))
                dat <- DBI::dbGetQuery(conn, q)
                DBI::dbDisconnect(conn)
                message("Close connection.")
                
                # return
                dat
            }
        ) %...>% (
            # expect a data frame here
            function(result) {
                w$hide()
                return(result)
            }
        ) %...!% (
            # error could come from `conn` or `res`
            function(error) {
                w$hide()
                stop(error)
            }
        )
        
    })
    
    output$tbl <- renderDataTable({
        
        res() %...>% {
            datatable(
                data          = sample_n(., 20, replace = TRUE),
                options       = list(dom = 'tip'),
                class         = 'cell-border stripe',
                fillContainer = TRUE,
                rownames      = FALSE
            )
        }
        
    })
    
    output$downloadRes <- downloadHandler(
        filename = function() {
            paste(input$form, "-", Sys.Date(), ".csv", sep = "")
        },
        content <- function(f) {
            res() %...>% {
                write_excel_csv(., f)
            }
        }
    )
    
}
