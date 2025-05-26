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

#' @title Fetch time series from FRED
#' @description Uses FRED API to retrieve data.
#' @param series_id FRED series ID (e.g., "FEDFUNDS").
#' @param api_key Your FRED API key.
#' @return Data frame with `date` and `value`.
#' @export
fetch_fred_series <- function(series_id, api_key = Sys.getenv("FRED_API_KEY")) {
  url <- sprintf("https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json", series_id, api_key)
  resp <- httr2::request(url) |>
    httr2::req_perform() |>
    httr2::resp_body_json()

  df <- as.data.frame(resp$observations)
  df$value <- as.numeric(df$value)
  df$date <- as.Date(df$date)
  df
}

