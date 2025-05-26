#' @title Post trading summary to Telegram or log
#' @description Extracts key result from memory and sends it to environment.
#' @param memory Agent belief state.
#' @param external_inputs Optional.
#' @return Updated memory.
#' @export
policy_post_summary <- function(memory, external_inputs = NULL) {
  closed <- memory$closed_positions %||% list()
  if (length(closed) == 0) {
    log_info("🛑 No closed trades to summarize.")
    return(memory)
  }

  summary <- paste0(
    "📈 Agent summary (", Sys.Date(), ")\n",
    "Closed: ", length(closed), " trades\n",
    "PnL: ", sum(purrr::map_dbl(closed, "pnl"), na.rm = TRUE)
  )

  if (!is.null(memory$config$telegram)) {
    send_text_to_telegram(
      token = memory$config$telegram$bot_token,
      chat_id = memory$config$telegram$chat_id,
      text = summary
    )
    log_info("📤 Summary posted to Telegram.")
  } else {
    log_info("📝 Summary:\n{summary}")
  }

  memory$last_post <- Sys.time()
  memory
}
