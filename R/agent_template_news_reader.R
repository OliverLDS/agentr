#' NewsReaderAgent: A Specialized Agent for News and Market Data
#'
#' Inherits from \code{XAgent} and extends its functionality with tools for:
#' - Local file-based interaction with users
#' - Fetching and parsing RSS feeds from curated sources
#' - Querying FRED and AlphaVantage economic data
#' - Fetching Binance cryptocurrency kline (candlestick) data
#'
#' This agent is intended to operate in an autonomous or semi-autonomous reading loop,
#' summarizing recent developments in news, economics, and markets.
#'
#' Key Methods:
#' \describe{
#'   \item{\code{run()}}{Agent main loop: checks for local user input and replies.}
#'   \item{\code{fetch_rss(rss_name)}}{Returns a parsed RSS feed for the given source name in \code{RSSlist}.}
#'   \item{\code{fetch_fred_series(series_id)}}{Fetches macroeconomic time series from the FRED API.}
#'   \item{\code{fetch_ts_daily_alphavantage(symbol, mode)}}{Downloads daily stock data from AlphaVantage.}
#'   \item{\code{fetch_binance_klines(...)}}{Retrieves candlestick data from Binance Futures API. Timezone is auto-set from agent.}
#' }
#'
#' @format An R6 class object.
#' @export
NewsReaderAgent <- R6::R6Class("NewsReaderAgent",
  inherit = XAgent,

  public = list(
    run = function() {
      self$local_check_and_reply()
    },
    
    # narrative
    fetch_rss = function(rss_name) fetch_rss(rss_name),
    
    # data
    fetch_fred_series = function(series_id) {fetch_fred_series(series_id, config = self$mind_state$tool_config$fred)},
    fetch_ts_daily_alphavantage = function(symbol, mode) {
      fetch_ts_daily_alphavantage(symbol, mode, config = self$mind_state$tool_config$alphavantage)
    },
    
    # crypto data
    fetch_binance_klines = function(...) fetch_binance_klines(tz = self$mind_state$timezone, ...)
  )
)

# name <- 'Zelina'
# mind_state <- list(
#   identity = "a no-nonsense crypto trader and former investment banker from Hong Kong.",
#   personality = "clear, smart, and slightly provocative.",
#   tone_guideline = "Use technical vocabulary when needed, but be practical. Prioritize clarity over fluff."
# )
# agent <- NewsReaderAgent$new(name, mind_state)
# agent$mind_state$timezone('Asia/Hong_Kong')
# 
# agent$set_config('fred')
# agent$fetch_fred_series('GDP')

# okx package
# live backtesting should be different agent from trading agent (so their tasks will not messy)





