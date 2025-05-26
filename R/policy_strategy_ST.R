#' @title Straddle Trader policy
#' @description Looks for volatility squeeze and places twin orders.
#' @param memory Agent belief state.
#' @param external_inputs Optional: live candle or volatility input.
#' @return Updated memory.
#' @export
policy_strategy_ST <- function(memory, external_inputs = NULL) {
  df <- memory$df_1m %||% fetch_okx_market_candles("ETH-USDT", "1m", 300)
  breakout <- detect_volatility_breakout(df)

  if (!is.null(breakout)) {
    memory$position_candidate <- list(
      side = "both",
      entry = breakout$entry,
      stop_loss = breakout$sl,
      take_profit = breakout$tp
    )
  }

  memory$volatility_score <- breakout$vol_score
  memory$decision_ts <- Sys.time()
  memory
}
