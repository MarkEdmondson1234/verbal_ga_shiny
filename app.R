library(shiny)             # R webapps
library(gentelellaShiny)   # ui theme
library(googleAuthR)       # auth login
library(googleAnalyticsR)  # get google analytics
library(googleLanguageR)   # talking
library(dygraphs)          # plots 
library(xts)               # time-series

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

ui <- gentelellaPage(
  menuItems = list(sideBarElement(gar_auth_jsUI("auth", approval_prompt_force = FALSE))),
  title_tag = "Google Analytics Talk",
  site_title = a(class="site_title", icon("phone"), span("GA Talk")),
  footer = "Made in Denmark",
  
  # shiny UI elements
  column(width = 12, authDropdownUI("auth_dropdown", inColumns = TRUE)),
  graph_box(boxtitle = "Google Analytics Data",
            subtitle = "Trend",
            dygraphOutput("trend_plot"),
            datepicker = dateRangeInput("datepicker", NULL, start = Sys.Date() - 300)),
  gl_talk_shinyUI("talk"),
  dashboard_box(width = 12, textOutput("text_analysis"), box_title = "Transcript")

)


server <- function(input, output, session) {
  
  # takes JSON client secrets from GAR_CLIENT_WEB_JSON
  gar_set_client(scopes = c("https://www.googleapis.com/auth/cloud-platform",
                            "https://www.googleapis.com/auth/analytics.readonly"))
  
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
  
  output$trend_plot <- renderDygraph({
    req(ga_data())
    ga_data <- ga_data()
    
    gadata_ts <- xts(ga_data$sessions, order.by = ga_data$date)
    
    gadata_ts %>% dygraph
    
  })
  
  transcript <- reactive({
    req(ga_data())
    req(input$datepicker)
    
    ga_data <- ga_data()
    ga_data$human_dates <- format(ga_data$date, "%A %B")
    ga_data$human_day <- sapply(format(ga_data$date, "%d"), getOrdinalNumber)
    
    trend <- round(coef(glm(sessions ~ date, data = ga_data))[[2]])
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
          "with a change of ", trend, "sessions per day")
    
  })
  
  output$text_analysis <- renderText({
    req(transcript()) 
    
    transcript()
  })
  
  callModule(gl_talk_shiny, "talk", transcript = transcript, controls = TRUE)

}

# Run the application 
shinyApp(ui = ui, server = server)

