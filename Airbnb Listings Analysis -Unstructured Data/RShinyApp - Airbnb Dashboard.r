# Installing the necessary packages required for analysis
# install.packages("shiny") 
# install.packages("shinyWidgets")
# install.packages("DT")
# install.packages("leaflet")
# install.packages("mongolite")
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("purr")
# install.packages("shinythemes")

# Loading the packages
library(shiny)
library(shinyWidgets)
library(DT)
library(leaflet)
library(mongolite)
library(dplyr)
library(tidyr)
library(purrr)
library(shinythemes)

# MongoDB connection and data fetching
connection_string <- 'mongodb+srv://arathi1:3k9tmBurSnT2N9QU@airbnb.qowdo2p.mongodb.net/?retryWrites=true&w=majority&appName=Airbnb'
airbnb_collection <- mongo(collection="listingsAndReviews", db="sample_airbnb", url=connection_string)
airbnb_data <- airbnb_collection$find()

# Convert MongoDB output to a data frame
airbnb_all <- as.data.frame(airbnb_data)

airbnb_all <- airbnb_all %>%
  mutate(
    longitude = map_dbl(address$location$coordinates, 1),
    latitude = map_dbl(address$location$coordinates, 2),
    Location = address$street,
    Bedrooms = as.integer(bedrooms),
    Beds = as.integer(beds),
    Bathrooms = as.numeric(bathrooms),
    Rating = review_scores$review_scores_rating,
    Host_ID = host$host_id,
    Host_URL = host$host_url,
    Host_Name = host$host_name,
    Host_Location = host$host_location,
    Host_About = host$host_about
  )

# UI definition
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
            body {font-family: 'Open Sans', sans-serif;}
            .navbar {background-color: #FF385C; color: white; border-color: #FF385C;}
            .navbar-brand {color: white; font-size: 24px; font-weight: bold; line-height: 20px; text-align: center; display: block;}
            .navbar .navbar-header .navbar-brand {margin-left: auto; margin-right: auto;}
            .navbar-toggle {display: none;} /* Hides the toggle button */
            .container-fluid > .navbar-header {float: none;} /* Centers the navbar-header */
            /* Remove black box and set title color to white */
            #airbnb-title {background-color: transparent; color: white;}
            /* Center the title */
            .navbar-header, .navbar-brand {width: 100%; text-align: center;}
        "))
  ),
  navbarPage(
    title = span(id = "airbnb-title", "Airbnb Listings"), # Title is now white and center-aligned
    inverse = TRUE,
    fluid = TRUE,
    tabPanel("",
             sidebarLayout(
               sidebarPanel(
                 selectInput("propertyType", "Property Type", choices = c("All", unique(airbnb_all$property_type))),
                 selectInput("bedType", "Bed Type", choices = c("All", unique(airbnb_all$bed_type))),
                 radioButtons("roomType", "Room Type", choices = c("All", unique(airbnb_all$room_type))),
                 pickerInput(
                   "amenitiesFilter",
                   "Amenities",
                   choices = c("TV", "Internet", "Wifi", "Air conditioning", "Cable TV", "Kitchen", "Pets allowed",
                               "Free parking on premises", "Family/kid friendly", "Private entrance", "Heating", "Breakfast",
                               "Elevator", "Lock on bedroom door", "Paid parking off premises", "Pets live on this property",
                               "Smoke detector", "Essentials"),
                   options = pickerOptions(actionsBox = TRUE),
                   multiple = TRUE
                 ),
                 sliderInput("priceRange", "Price Range", min = min(airbnb_all$price, na.rm = TRUE), max = max(airbnb_all$price, na.rm = TRUE), value = c(min(airbnb_all$price, na.rm = TRUE), max(airbnb_all$price, na.rm = TRUE)))
               ),
               mainPanel(
                 tabsetPanel(
                   id = "tabs",
                   type = "tabs",
                   tabPanel("Map", leafletOutput("mapOutput")),
                   tabPanel("Property Description", DTOutput("descriptionTable")),
                   tabPanel("Property Details", DTOutput("detailsTable")),
                   tabPanel("Neighbourhood Details", DTOutput("neighbourhoodTable")),
                   tabPanel("Host Details", DTOutput("hostTable")),
                 )
               )
             )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  filtered_data <- reactive({
    df <- airbnb_all
    
    if (input$propertyType != "All") {
      df <- df %>% filter(property_type == input$propertyType)
    }
    if (input$bedType != "All") {
      df <- df %>% filter(bed_type == input$bedType)
    }
    if (input$roomType != "All") {
      df <- df %>% filter(room_type == input$roomType)
    }
    if (!is.null(input$amenitiesFilter) && length(input$amenitiesFilter) > 0) {
      df <- df %>% filter(map_lgl(amenities, ~all(input$amenitiesFilter %in% .)))
    }
    df <- df %>% filter(price >= input$priceRange[1], price <= input$priceRange[2])
    
    df
  })
  
  output$mapOutput <- renderLeaflet({
    leaflet(filtered_data()) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        lng = ~longitude,
        lat = ~latitude,
        popup = ~name,
        clusterOptions = markerClusterOptions()
      )
  })
  
  output$descriptionTable <- renderDT({
    datatable(filtered_data()[, c("listing_url", "name", "description")],
              options = list(pageLength = 5, scrollX = TRUE), rownames = FALSE)
  })
  
  output$detailsTable <- renderDT({
    datatable(filtered_data()[, c("name", "property_type", "room_type", "bed_type", "price", "Location", "Bedrooms", "Beds", "Bathrooms", "Rating")],
              options = list(pageLength = 5, scrollX = TRUE), rownames = FALSE)
  })
  
  output$neighbourhoodTable <- renderDT({
    datatable(filtered_data()[, c("listing_url", "name", "neighborhood_overview")],
              options = list(pageLength = 5, scrollX = TRUE), rownames = FALSE)
  })
  
  
  output$hostTable <- renderDT({
    datatable(filtered_data()[, c("Host_ID", "Host_Name", "Host_URL", "Host_Location", "Host_About")],
              options = list(pageLength = 5, scrollX = TRUE), rownames = FALSE)
  })
}

# Run the Shiny app
shinyApp(ui, server)
