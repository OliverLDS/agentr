#' @title Directional Trend strategy policy
#' @description Runs DT logic and updates memory with signal and stats.
#' @param memory Agent belief state.
#' @param external_inputs Optional: market data, if not stored in memory.
#' @return Updated memory.
#' @export
policy_strategy_DT <- function(memory, external_inputs = NULL) {
  df <- memory$df_1m %||% fetch_okx_market_candles("ETH-USDT", "1m", 300)

  signal <- detect_DT_signal(df)
  memory$latest_signal <- signal
  memory$decision_ts <- Sys.time()

  if (!is.null(signal$direction)) {
    memory$position_candidate <- list(
      side = signal$direction,
      strength = signal$strength,
      confidence = signal$score
    )
  }

  memory
}
