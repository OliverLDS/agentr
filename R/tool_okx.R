#' Get OKX market ticker data
#' @export
tool_okx_ticker <- function(symbol = "ETH-USDT") {
  url <- paste0("https://www.okx.com/api/v5/market/ticker?instId=", symbol)
  jsonlite::fromJSON(url)$data[[1]]
}

#' Simulate placing an order on OKX (mockup or real via API)
#' @export
tool_okx_place_order <- function(inst_id, side, sz, px) {
  list(
    instId = inst_id,
    side = side,
    sz = sz,
    px = px,
    order_id = paste0("mock-", sample(100000:999999, 1)),
    status = "submitted"
  )
}

#' Mock order status check
#' @export
tool_okx_check_order_status <- function(inst_id, order_id) {
  list(
    instId = inst_id,
    order_id = order_id,
    status = "filled",
    filled_px = 1801.23,
    filled_sz = 0.01
  )
}

#' @title Fetch OHLC data from OKX
#' @description Downloads up to 100 bars of historical data from OKX.
#' @param inst_id Instrument ID (e.g., "ETH-USDT").
#' @param bar Timeframe (e.g., "1m", "15m").
#' @param before Timestamp in ms to paginate backwards.
#' @param limit Maximum number of records (default 100).
#' @return Dataframe of OHLC candles.
#' @export
fetch_okx_ohlc <- function(inst_id, bar = "1m", before = NULL, limit = 100) {
  url <- "https://www.okx.com/api/v5/market/candles"
  query <- list(instId = inst_id, bar = bar, limit = limit)
  if (!is.null(before)) query$before <- before

  resp <- httr2::request(url) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_perform() |>
    httr2::resp_body_json()

  out <- do.call(rbind, resp$data)
  colnames(out) <- c("ts", "open", "high", "low", "close", "volume", "volCcy", "volQuote", "confirm", "inst_type")
  out <- as.data.frame(out)
  out$ts <- as.numeric(out$ts)
  out$open <- as.numeric(out$open)
  out$high <- as.numeric(out$high)
  out$low  <- as.numeric(out$low)
  out$close <- as.numeric(out$close)
  out
}

#' @title Simulated order executor
#' @description Returns mock fill confirmation for testing.
#' @param order Order object from memory.
#' @return Mock confirmation message.
#' @export
place_mock_order <- function(order) {
  message <- sprintf(
    "[SIMULATED] %s order placed at %.2f → SL %.2f / TP %.2f",
    toupper(order$side), order$entry, order$sl, order$tp
  )
  log_info(message)
  return(message)
}

