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

