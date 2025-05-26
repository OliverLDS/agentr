#' @title Zone Trapper strategy policy
#' @description Analyzes bounce zones and sets trap logic.
#' @param memory Agent belief state.
#' @param external_inputs Market input (optional).
#' @return Updated memory.
#' @export
policy_strategy_ZT <- function(memory, external_inputs = NULL) {
  df <- memory$df_15m %||% fetch_okx_market_candles("ETH-USDT", "15m", 300)
  zones <- detect_support_resistance_zones(df)
  candidate <- evaluate_trap(zones, df)

  memory$trap_zones <- zones
  memory$position_candidate <- candidate
  memory$decision_ts <- Sys.time()
  memory
}
