#' Collects data from APIs like OKX, FRED, RSS feeds
#' @export
policy_data_collector <- function(input, memory, goal, tools) {
  output <- list(
    ticker = tools$okx_ticker("ETH-USDT"),
    macro  = tools$fred_series("FEDFUNDS"),
    news   = tools$fetch_rss()
  )
  memory <- update_memory(memory, "last_collected", Sys.time())
  memory <- update_memory(memory, "raw_data", output)
  list(output = output, memory = memory)
}
