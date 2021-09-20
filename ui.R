# UI ---
suppressPackageStartupMessages({
    library(tidyverse)
    library(magrittr)
    library(leaflet)
    library(waiter)
    library(shiny)
    library(shinyWidgets)
    library(shinydashboard)
    library(shinydashboardPlus)
})

# Header
header <- dashboardHeader(
    title = 'Sample Management',
    leftUi = tagList(
        # Clear filters button - in header
        actionBttn(
            inputId = "clear_filters",
            label = "Clear Filters", 
            style = "minimal",
            # color = "royal",
            size = 'sm', 
            icon = icon('soap', lib = 'font-awesome')
        ),
        actionBttn(
            inputId = "reload_database",
            label = "Reload database", 
            style = "minimal",
            # color = "royal",
            size = 'sm', 
            icon = icon('redo-alt', lib = 'font-awesome')
        )
    )
)

# Sidebar
sidebar <- dashboardSidebar(
    width = '20em',
    minified = TRUE,
    sidebarMenu(
        id = 'sidebar_menu',
        menuItem(
            text = 'Filter',
            tabName = 'sidebar_filter',
            icon = icon('filter', lib = 'font-awesome'),
            
            # Filter on Institution the samples came from
            menuSubItem(
                text = 'Institution ',
                tabName = 'tab_institution',
                icon = icon('university', lib = 'font-awesome')
            ),
            conditionalPanel(
                condition = " input.sidebar_menu == 'tab_institution' ",
                uiOutput('filter_institution')
            ),
            
            # Filter on taxonomic level
            menuSubItem(
                text = 'Taxonomic Level',
                tabName = 'tab_taxonomic_level',
                icon = icon('pagelines', lib = 'font-awesome')
            ),
            conditionalPanel(
                condition = " input.sidebar_menu == 'tab_taxonomic_level' ",
                uiOutput('filter_taxonomic_level_family'),
                uiOutput('filter_taxonomic_level_genus'),
                uiOutput('filter_taxonomic_level_species')
            ),
            
            # Filter by collection date
            menuSubItem(
                text = 'Collection Date',
                tabName = 'tab_collection_date',
                icon = icon('calendar-alt', lib = 'font-awesome')
            ),
            conditionalPanel(
                condition = " input.sidebar_menu == 'tab_collection_date' ",
                uiOutput('filter_collection_date')
            ),
            
            # Filter by who collected the samples
            menuSubItem(
                text = 'Collector',
                tabName = 'tab_collector',
                icon = icon('users', lib = 'font-awesome')
            ),
            conditionalPanel(
                condition = " input.sidebar_menu == 'tab_collector' ",
                uiOutput('filter_collector')
            ),
            
            # Filter on life stage
            menuSubItem(
                text = 'Life Stage',
                tabName = 'tab_life_stage',
                icon = icon('id-card', lib = 'font-awesome')
            ),
            conditionalPanel(
                condition = " input.sidebar_menu == 'tab_life_stage' ",
                uiOutput('filter_life_stage')
            ),
            
            # Filter on sample sex
            menuSubItem(
                text = 'Sex',
                tabName = 'tab_sex',
                icon = icon('venus-mars', lib = 'font-awesome')
            ),
            conditionalPanel(
                condition = " input.sidebar_menu == 'tab_sex' ",
                uiOutput('filter_sex')
            ),
            
            # Filter on country where sample was caught
            menuSubItem(
                text = 'Country',
                tabName = 'tab_country',
                icon = icon('globe-asia', lib = 'font-awesome')
            ),
            conditionalPanel(
                condition = " input.sidebar_menu == 'tab_country' ",
                uiOutput('filter_country')
            ),
            
            br(),
            
            # Download data (with filters applied)
            downloadBttn(
                outputId = "download_filtered_data",
                style = "bordered",
                color = 'primary',
                size = 'sm'
            )
        ),
        menuItem(
            text = 'Upload samples',
            icon = icon('upload', lib = 'font-awesome'),
            tabName = 'sidebar_sample_upload',
            
            br(),
            p('Upload a valid sample file with all key fields'),
            p('of information.'),
            
            # Upload a filled-in-template file
            fileInput(
                inputId = "tab_upload_sample_template",
                label = NULL,
                accept = '.csy',
                buttonLabel = "Upload...",
                multiple = TRUE, 
                placeholder = 'Click here to upload'
            ),
            
            br(),
            p('Download a template file with all the'),
            p('required fields.'),
            downloadBttn(
                outputId = "downalod_template_file",
                style = "bordered",
                color = 'primary',
                size = 'sm'
            )
        ),
        # Generate a plot
        prettySwitch(
            inputId = "plot_samples",
            label = "Plot samples?",
            status = "success",
            fill = TRUE,
            bigger = TRUE
        ),
        conditionalPanel(
            condition = " input.plot_samples == true ",
            uiOutput('plot_providers')
        )
    )
)


# Body
body <- uiOutput('main_layout')

# Page 
dashboardPage(
    skin = 'yellow', 
    preloader = list(html = spin_1(), color = "#333e48"),
    header = header,
    sidebar = sidebar,
    body = body,
    controlbar = dashboardControlbar(collapsed = TRUE, skinSelector()),
    title = "Skin Selector"
)
