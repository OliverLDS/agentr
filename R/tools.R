# example_tool_terminate <- function(memory, ...) {
#   list(memory = memory, output = "Terminating flow.")
# }
# 
# example_tool_uppercase <- function(memory, input, ...) {
#   transformed_text <- toupper(input)
#   new_memory <- add_message(memory, "assistant", transformed_text)
#   list(memory = new_memory, output = transformed_text)
# }
# 
# TOOL_COLLECTION <- list(
#   "terminate" = example_tool_terminate,
#   "uppercase" = example_tool_uppercase
# )


#' Tool: Get OKX Ticker Info
#' @param symbol E.g., "BTC-USDT"
#' @return Latest ticker info as a list
tool_okx_ticker <- function(symbol = "BTC-USDT") {
  url <- paste0("https://www.okx.com/api/v5/market/ticker?instId=", symbol)
  jsonlite::fromJSON(url)$data[[1]]
}

#' Tool: Get FRED Indicator
#' @param series_id Like "FEDFUNDS"
#' @return Data.frame of date and value
tool_fred_series <- function(series_id = "FEDFUNDS") {
  key <- Sys.getenv("FRED_API_KEY")
  url <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                "series_id=", series_id,
                "&api_key=", key,
                "&file_type=json")
  data <- jsonlite::fromJSON(url)
  return(data.frame(date = data$observations$date, value = as.numeric(data$observations$value)))
}