#' @title Simulate fills and exits for virtual positions
#' @description Updates memory with filled positions and closed trades.
#' @param memory Agent belief state.
#' @param external_inputs Optional: latest candles.
#' @return Updated memory.
#' @export
policy_simulate_fills <- function(memory, external_inputs = NULL) {
  df <- memory$df_1m %||% fetch_okx_market_candles("ETH-USDT", "1m", 300)
  positions <- memory$open_positions %||% list()
  closed <- list()

  for (i in seq_along(positions)) {
    pos <- positions[[i]]
    result <- check_virtual_exit(pos, df)

    if (result$closed) {
      closed[[length(closed) + 1]] <- result
      positions[[i]] <- NULL
    } else {
      positions[[i]] <- result$updated_position
    }
  }

  memory$open_positions <- positions
  memory$closed_positions <- c(memory$closed_positions %||% list(), closed)
  memory$last_fill_check <- Sys.time()
  memory
}
