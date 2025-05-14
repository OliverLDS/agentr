#' Get FRED time series data
#' @export
tool_fred_series <- function(series_id = "FEDFUNDS") {
  key <- Sys.getenv("FRED_API_KEY")
  if (nchar(key) == 0) stop("Missing FRED_API_KEY")
  url <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                "series_id=", series_id,
                "&api_key=", key,
                "&file_type=json")
  data <- jsonlite::fromJSON(url)
  df <- data.frame(
    date = as.Date(data$observations$date),
    value = as.numeric(data$observations$value),
    stringsAsFactors = FALSE
  )
  return(df)
}
