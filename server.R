# Source accessory functions ---
source('scripts/buildSampleTemplate.R')
source('scripts/importUserSheet.R')

# Pool connection - handles disconnect for us
con <- pool::dbPool(
  drv = RSQLite::SQLite(),
  dbname = 'example-data/DB-directory/DB-example.sqlite'
)

# Column specification
col_spec <- readr::read_rds(
  'example-data/template-sample-sheet-column-specification.rds'
)

# Server function ---
server <- function(input, output, session) {
  # Convert connection to tibble - easy manipulation
  df <- dplyr::tbl(con, 'mandatory_information') %>%
    collect() %>%
    mutate(
      collection_date = readr::parse_date(
        x = collection_date,
        format = '%d/%m/%Y'
      )
    )
  
  # Create a reactiveValues object - will adapt to filter inputs automatically
  reac <- reactiveValues(data = NULL)
  reac$data <- df
  
  # Filter database information ---
  
  # Sample institution
  observeEvent(input$filter_institution, {
    reac$data <- reac$data %>%
      filter(
        specimen_id_description %in% input$filter_institution
      )
  })
  
  # Filter on taxonomic levels
  observeEvent(input$filter_taxonomic_level_family, {
    reac$data <- reac$data %>%
      filter(
        family %in% input$filter_taxonomic_level_family
      )
  })
  
  observeEvent(input$filter_taxonomic_level_genus, {
    reac$data <- reac$data %>%
      filter(
        genus %in% input$filter_taxonomic_level_genus
      )
  })
  
  observeEvent(input$filter_taxonomic_level_species, {
    reac$data <- reac$data %>%
      filter(
        species %in% input$filter_taxonomic_level_species
      )
  })
  
  # Filter on collection date
  observeEvent(input$filter_collection_date, {
    reac$data <- reac$data %>%
      filter(
        collection_date %in% input$filter_collection_date
      )
  })
  
  # Filter on collector
  observeEvent(input$filter_collector, {
    reac$data <- reac$data %>%
      filter(
        collector %in% input$filter_collector
      )
  })
  
  # Filter life stage
  observeEvent(input$filter_country, {
    reac$data <- reac$data %>%
      filter(
        country %in% input$filter_country
      )
  })
  
  # Filter on sex
  observeEvent(input$filter_sex, {
    reac$data <- reac$data %>%
      filter(
        sex %in% input$filter_sex
      )
  })
  
  # Filter on country
  observeEvent(input$filter_sex, {
    reac$data <- reac$data %>%
      filter(
        sex %in% input$filter_sex
      )
  })
  
  # Render the output table (after all the filtering)
  output$tbl_mandatory <- DT::renderDataTable({
    DT::datatable(
      data = reac$data,
      options = list(
        scrollX = 1000,
        scrollY = 725,
        pageLength = 25
      )
    )
  })
  
  # Clear filters applied to data-frame
  observeEvent(input$clear_filters, {
    reac$data <- df
  })
  
  # Re-load database ---
  observeEvent(input$reload_database, {
    session$reload()
  })
  
  # Download current filtered data ---
  output$download_filtered_data <- downloadHandler(
    filename = "sample-information-filtered.csv",
    content = function(file) {
      write.csv(reac$data, file, row.names = FALSE)
    }
  )
  
  # Download template file ---
  output$downalod_template_file <- downloadHandler(
    filename = 'sample-submission-template.csv', 
    content = function(file) {
      write(
        x = paste(names(col_spec$cols), collapse = ','),
        file = file
      )
    }
  )
  
  # Upload the users sample sheet after passing checks
  observeEvent(input$tab_upload_sample_template, {
    
    # Check the data can be imported OK
    df_imports <- checkImport(
      input = input$tab_upload_sample_template$datapath, 
      col_spec = col_spec
    )
    
    if (!tibble::is_tibble(df_imports)) {
      showModal(
        session = session,
        modalDialog(
          title = 'Upload Error',
          easyClose = TRUE,
          'There was an issue with the provided samplesheet.
          Check that there are the correct columns and no duplicate sample
          identifiers.'
        )
      )
    } else {
      
      # Check for NAs in columns
      na_verdict <- checkNA(df_imports)
      
      if (!isTRUE(na_verdict)) {
        showModal(
          session = session,
          modalDialog(
            title = 'NAs in columns',
            easyClose = TRUE,
            glue::glue(
              'NA values were found in the following columns',
              '
              - {na_verdict}
              ',
              .sep = '\n'
            )
          )
        )
      } else {
        # Check date format is dd/mm/yyyy
        date_verdict <- checkDateFormat(df_imports)
        
        if (!isTRUE(date_verdict)) {
          showModal(
            session = session,
            modalDialog(
              title = 'Incorrect Date Format',
              easyClose = TRUE,
              "Check the date format in the selected file. All dates should be
              in dd/mm/yyy format e.g. 01/01/1901"
            )
          )
        } else {
          # Check for identical rows between file and database
          rows_verdict <- checkDuplicateRows(
            tib = df_imports,
            con = con
          )
          
          if (!isTRUE(rows_verdict)) {
            showModal(
              session = session,
              modalDialog(
                title = 'Duplicate rows between the database and uploaded file',
                easyClose = TRUE,
                glue::glue(
                  "Duplicated rows were identified between the uploaded file
                and the database. Check rows with the following sample IDs -
                {rows_verdict}"
                )
              )
            )
          } else {
            # Check for duplicated sample identifiers between file and DB
            sampleid_verdict <- checkDuplicateSampleIds(
              tib = df_imports,
              con = con
            )
            
            if (!isTRUE(sampleid_verdict)) {
              showModal(
                session = session,
                modalDialog(
                  title = 'Duplicate sample identifiers between the database and uploaded file',
                  easyClose = TRUE,
                  glue::glue(
                    "Duplicated identifiers were identified between the uploaded file
                    and the database - {rows_verdict}"
                  )
                )
              )
            } else {
              # Ingest the data into the database
              ingestFile(tib = df_imports, con = con)
              showModal(
                session = session,
                modalDialog(
                  title = 'Uploaded! Samples are now in the database',
                  easyClose = TRUE,
                  'Samples uploaded. Refresh the database by clicking the button
                  at the top of the page.'
                )
              )
            }
          }
        } 
      }
    }
  })
  
  # Plot samples ---
  output$plot_leaflet <- renderLeaflet({
    df <- reac$data %>%
      select(
        sample_id, 
        longitude = decimal_longitude, 
        latitude = decimal_latitude
      ) %>%
      filter(
        across(
          2:3,
          ~!is.na(.x)
        ),
      )
    
    if(nrow(df) == 0) {
      showModal(
        session = session,
        modalDialog(
          title = "Can't plot samples",
          easyClose = TRUE,
          "The current selection of samples cannot be plotted on the map as
          they don't have any latitude/longitude data."
        )
      )
    } else {
      df %>%
        leaflet() %>%
        addTiles() %>%
        addProviderTiles(input$plot_providers) %>%
        addMarkers(
          ~longitude,
          ~latitude,
          popup = ~as.character(sample_id),
          label = ~as.character(sample_id)
        )
    }
    
  })
  
  # Body Layout (Table and Plot) ---
  output$main_layout <- renderUI({
    if (input$plot_samples) {
      dashboardBody(
        fluidRow(
          column(
            width = 12,
            box(
              title = 'Sample Information',
              id = 'main_table',
              status = 'success',
              solidHeader = TRUE,
              collapsible = TRUE, 
              width = 12,
              icon = icon('table', lib = 'font-awesome'),
              DT::dataTableOutput('tbl_mandatory')
            )
          )
        ),
        fluidRow(
          column(
            width = 12,
            box(
              title = 'Sample locations',
              id = 'main_plot',
              status = 'maroon',
              solidHeader = TRUE,
              collapsible = TRUE, 
              width = 12,
              icon = icon('map-marker-alt', lib = 'font-awesome'),
              leafletOutput('plot_leaflet', height = '65em')
            )
          )
        )
      )
    } else {
      dashboardBody(
        fluidRow(
          column(
            width = 12,
            box(
              title = 'Sample Information',
              id = 'main_table',
              status = 'success',
              solidHeader = TRUE,
              collapsible = TRUE,
              width = 12,
              icon = icon('table', lib = 'font-awesome'),
              DT::dataTableOutput('tbl_mandatory')
            )
          )
        )
      )
    }
  })
  
  # UI sidebar widgets ---
  
  # UI filter: Institution from which the samples originated
  output$filter_institution <- renderUI({
    institutions <- reac$data %>%
      pull(specimen_id_description) %>%
      unique()
    
    pickerInput(
      inputId = "filter_institution",
      label = "Select institution",
      choices = institutions,
      multiple = TRUE,
      options = list(
        `live-search` = TRUE,
        `actions-box` = TRUE)
    )
  })
  
  # UI filter: Taxonomic level
  output$filter_taxonomic_level_family <- renderUI({
    family <- reac$data %>%
      pull(family) %>%
      unique()
    
    pickerInput(
      inputId = "filter_taxonomic_level_family",
      label = "Filter by Family", 
      choices = family,
      multiple = TRUE,
      options = list(
        `live-search` = TRUE
      )
    )
  })
  
  output$filter_taxonomic_level_genus <- renderUI({
    genus <- reac$data %>%
      pull(genus) %>%
      unique()
    
    pickerInput(
      inputId = "filter_taxonomic_level_genus",
      label = "Filter by Genus", 
      choices = genus,
      multiple = TRUE,
      options = list(
        `live-search` = TRUE
      )
    )
  })
  
  output$filter_taxonomic_level_species <- renderUI({
    species <- reac$data %>%
      pull(species) %>%
      unique()
    
    pickerInput(
      inputId = "filter_taxonomic_level_species",
      label = "Filter by Species", 
      choices = species,
      multiple = TRUE,
      options = list(
        `live-search` = TRUE
      )
    )
  })
  
  # UI filter: Collection date
  output$filter_collection_date <- renderUI({
    date_min <- reac$data %>% pull(collection_date) %>% min()
    date_max <- reac$data %>% pull(collection_date) %>% max()
    
    dateRangeInput(
      inputId = 'filter_collection_date',
      label = 'Filter samples by collection date',
      start = date_min, 
      end = date_max
    )
  })
  
  # UI filter: Collector
  output$filter_collector <- renderUI({
    collectors <- reac$data %>% pull(collector) %>% unique()
    
    pickerInput(
      inputId = "filter_collector",
      label = "Filter by collector", 
      choices = collectors, 
      multiple = TRUE,
      options = list(
        `live-search` = TRUE
      )
    )
  })
  
  # UI filter: life stage
  output$filter_life_stage <- renderUI({
    life_stage <- reac$data %>% pull(life_stage) %>% unique()
    
    pickerInput(
      inputId = "filter_life_stage",
      label = "Filter by life-stage", 
      choices = life_stage, 
      multiple = TRUE,
      options = list(
        `live-search` = TRUE
      )
    )
  })
  
  # UI filter: Sex
  output$filter_sex <- renderUI({
    sex <- reac$data %>% pull(sex) %>% unique()
    
    checkboxGroupButtons(
      inputId = "filter_sex",
      label = "Select sex",
      choices = sex,
      justified = TRUE,
      checkIcon = list(
        yes = icon(
          "check-circle", 
          lib = "font-awesome",
        )
      )
    )
  })
  
  # UI filter: Country
  output$filter_country <- renderUI({
    countries <- reac$data %>% pull(country) %>% unique()
    
    pickerInput(
      inputId = "filter_country",
      label = "Filter by country", 
      choices = countries, 
      multiple = TRUE,
      options = list(
        `live-search` = TRUE
      )
    )
  })
  
  # Plot providers
  observeEvent(input$plot_samples, {
    prov <- names(leaflet::providers)
    
    output$plot_providers <- renderUI({
      pickerInput(
        inputId = "plot_providers",
        label = "Map overlays", 
        choices = prov, 
        multiple = FALSE,
        options = list(
          `live-search` = TRUE
        )
      )
    })
  })
}


