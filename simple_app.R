library(shiny)             # R webapps
library(googleAuthR)       # auth login

# takes JSON client secrets from GAR_CLIENT_WEB_JSON
# set before calls to googleAnalyticsR to make sure it doesn't use default project.
gar_set_client(scopes = c("https://www.googleapis.com/auth/analytics.readonly"))

library(googleAnalyticsR)  # get google analytics

ui <- fluidPage(
  gar_auth_jsUI("auth"),
  
  # shiny UI elements
  column(width = 12, authDropdownUI("auth_dropdown", 
                                    inColumns = TRUE)),
  dateRangeInput("datepicker", NULL, start = Sys.Date() - 300),
  plotOutput("trend_plot")
  
)


server <- function(input, output, session) {
  
  # get auth token
  auth <- callModule(gar_auth_js, "auth")
  
  # get ga_accounts
  ga_accounts <- reactive({
    req(auth())
    
    with_shiny(
      ga_account_list,
      shiny_access_token = auth()
    )
    
  })
  
  view_id <- callModule(authDropdown, "auth_dropdown", 
                        ga.table = ga_accounts)
  
  ga_data <- reactive({
    req(view_id())
    req(input$datepicker)
    
    with_shiny(
      google_analytics,
      view_id(),
      date_range = input$datepicker,
      dimensions = "date",
      metrics = "sessions",
      max = -1,
      shiny_access_token = auth()
    )
  })
  
  output$trend_plot <- renderPlot({
    req(ga_data())
    ga_data <- ga_data()
    
    plot(ga_data$sessions, type = "l")
    
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

