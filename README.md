# Talk to me, Google Analytics

A simple Shiny app to display some Google Analytics data, and talk over some statistics of that data, using `googleAnalyticsR` and `googleLanguageR::gl_talk()`

## Install

It needs these libraries:

```r
library(shiny)             # R webapps
library(gentelellaShiny)   # ui theme
library(googleAuthR)       # auth login
library(googleAnalyticsR)  # get google analytics
library(googleLanguageR)   # talking
library(dygraphs)          # plots 
library(xts)               # time-series
```

It needs the CRAN versions of these libraries:

```r
install.packages(c("shiny","googleAnalyticsR", "dygraphs", "xts"))
```
...and the GitHub versions of these:

```r
remotes::install_github("MarkEdmondson1234/googleAuthR")
remotes::install_github("ropensci/googleLanguageR")
remotes::install_github("MarkEdmondson1234/gentelellaShiny")
```

## Auth

You then need authentication setup as per the libraries installation instructions.

For this app in particular I has these environment arguments set in my `.Renviron`:

* `GAR_CLIENT_WEB_JSON` pointing at my download client details (web app) for my project that has Google Analytics and Google Text-to-speech APIs activated for `gar_set_client()`
* Turned off auto auth for `googleAnalyticsR` by commenting out `GA_AUTH_FILE` for `google_analytics()`
* Had my authentication service JSON for cloud platform set in `GL_AUTH` for `gl_talk()`

## Screenshot

![](gl_talk.png)