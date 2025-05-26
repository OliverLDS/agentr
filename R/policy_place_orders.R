#' @title Place or simulate orders based on strategy output
#' @description Converts `position_candidate` into active virtual orders.
#' @param memory Agent belief state.
#' @param external_inputs Optional.
#' @return Updated memory.
#' @export
policy_place_orders <- function(memory, external_inputs = NULL) {
  if (is.null(memory$position_candidate)) {
    log_info("📭 No signal to place order.")
    return(memory)
  }

  pos <- memory$position_candidate
  df <- memory$df_1m %||% fetch_okx_market_candles("ETH-USDT", "1m", 300)
  now_price <- tail(df$close, 1)

  new_order <- list(
    symbol = "ETH-USDT",
    side = pos$side,
    entry = now_price,
    sl = pos$stop_loss %||% (now_price * 0.98),
    tp = pos$take_profit %||% (now_price * 1.02),
    ts = Sys.time()
  )

  memory$open_positions <- c(memory$open_positions %||% list(), list(new_order))
  memory$last_order_placed <- Sys.time()
  memory$position_candidate <- NULL  # clear once placed
  log_info("📝 Simulated order placed: {new_order$side} at {round(now_price, 2)}")
  memory
}
