library(shiny)             # R webapps
library(googleAuthR)       # auth login

# takes JSON client secrets from GAR_CLIENT_WEB_JSON
# set before calls to googleAnalyticsR to make sure it doesn't use default project.
gar_set_client(scopes = c("https://www.googleapis.com/auth/cloud-platform",
                          "https://www.googleapis.com/auth/analytics.readonly"))

library(googleAnalyticsR)  # get google analytics
library(googleLanguageR)   # talking


# to make nice ordinals
# https://stackoverflow.com/questions/40039903/r-add-th-rd-and-nd-to-dates/40040338
getOrdinalNumber <- function(num) {
  num <- as.numeric(num)
  result <- ""
  if (!(num %% 100 %in% c(11, 12, 13))) {
    result <- switch(as.character(num %% 10), 
                     "1" = {paste0(num, "st")}, 
                     "2" = {paste0(num, "nd")},
                     "3" = {paste0(num, "rd")},
                     paste0(num,"th"))
  } else {
    result <- paste0(num, "th")
  }
  result
}


ui <- fluidPage(
  gar_auth_jsUI("auth", approval_prompt_force = FALSE),
  
  # shiny UI elements
  column(width = 12, authDropdownUI("auth_dropdown", inColumns = TRUE)),
  dateRangeInput("datepicker", NULL, start = Sys.Date() - 300),
  plotOutput("trend_plot"),
  gl_talk_shinyUI("talk"),
  textOutput("text_analysis")
  
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
  
  view_id <- callModule(authDropdown, "auth_dropdown", ga.table = ga_accounts)
  
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
  
  transcript <- reactive({
    req(ga_data())
    req(input$datepicker)
    
    ga_data <- ga_data()
    ga_data$human_dates <- format(ga_data$date, "%A %B")
    ga_data$human_day <- sapply(format(ga_data$date, "%d"), getOrdinalNumber)
    
    trend <- round(coef(glm(sessions ~ date, data = ga_data))[[2]],2)*30
    paste("For the period covering", 
          format(input$datepicker[1],"%A %B"), "the",
          getOrdinalNumber(format(input$datepicker[1],"%d")),
          "to", 
          format(input$datepicker[2],"%A %B"), "the",
          getOrdinalNumber(format(input$datepicker[2],"%d")),
          ". The most daily sessions was ", max(ga_data$sessions),
          ", on", ga_data[which.max(ga_data$sessions),"human_dates"], "the",
          ga_data[which.max(ga_data$sessions),"human_day"],
          ". The lowest number of daily sessions was", min(ga_data$sessions),
          ", on", 
          ga_data[which.min(ga_data$sessions),"human_dates"], "the",
          ga_data[which.min(ga_data$sessions),"human_day"],
          ". The overall mean average was", 
          round(mean(ga_data$sessions),2),
          ". Overall the trend is ",
          if(trend>0) "upwards" else if(trend==0) "static" else "downwards",
          "with a change of ", trend, "sessions per month")
    
  })
  
  output$text_analysis <- renderText({
    req(transcript()) 
    
    transcript()
  })
  
  callModule(gl_talk_shiny, "talk", transcript = transcript, 
             controls = TRUE, 
             gender = "FEMALE")
  
}

# Run the application 
shinyApp(ui = ui, server = server)

