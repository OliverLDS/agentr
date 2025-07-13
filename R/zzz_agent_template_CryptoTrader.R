#' CryptoTraderAgent: A Specialized XAgent for Crypto Trading via OKX
#'
#' This R6 class inherits from `XAgent` and equips it with OKX-specific trading functions.
#' It includes methods for market data retrieval, order placement, leverage control, backtest result viewing,
#' and loading local OHLCV and strategy data.
#'
#' @section Inheritance:
#' Inherits from `XAgent`, and extends it with crypto trading capabilities.
#'
#' @section Public Methods:
#' - `run()`: Trigger autonomous agent logic.
#' - `initialize(...)`: Constructor, also initializes empty `order_ids`.
#' - `load_okxr()`: Loads OKX API wrappers for market/account/order functions.
#' - `set_okx_candle_dir(dir)`: Set path for OKX candle data.
#' - `get_okx_candle_rds_path(inst_id, bar)`: Get RDS path for specific instrument/bar.
#' - `set_cdd_bt_dir(dir)`, `get_cdd_bt_dir()`: Set and get path for CDD backtest results.
#' - `load_candles(inst_id, bar)`: Load saved OHLCV data from RDS.
#' - `sync_and_save_candles(df_new, inst_id, bar)`: Sync and save new candle data to RDS.
#' - `load_bt_summary()`: Load and sort CDD backtest summary.
#' - `view_bt_equity_curve(inst_id, strategy)`, etc.: Open backtest charts and stats.
#'
#' @section OKX Wrappers:
#' The following functions are loaded dynamically via `load_okxr()`:
#' - `get_mark_price()`
#' - `get_candles_okx()`, `get_history_candles_okx()`
#' - `get_asset_balances()`, `get_account_balance()`, `get_account_leverage_info()`, `get_account_positions()`
#' - `set_leverage()`
#' - `place_order()`, `cancel_order()`, `close_position()`
#' - `check_order()`, `check_order_pending()`
#'
#' @section Utilities:
#' - `rename_ohlcv_from_okx`: Imported from `okxr::standardize_ohlcv_names`.
#' - `detect_time_gaps`: Standalone function for detecting data gaps.
#'
#' @export
CryptoTraderAgent <- R6::R6Class("CryptoTraderAgent",
  inherit = XAgent,
  public = list(

    run = function() {
      self$local_check_and_reply()
    },

    #' Constructor
    #' @param ... Arguments passed to parent `XAgent`
    initialize = function(...) {
      super$initialize(...)
      self$mind_state$order_ids <- character(0)
    },

    #' Load OKX wrapper functions into agent methods
    get_mark_price = NULL,
    get_candles_okx = NULL,
    get_history_candles_okx = NULL,
    get_asset_balances = NULL,
    get_account_balance = NULL,
    get_account_leverage_info = NULL,
    get_account_positions = NULL,
    set_leverage = NULL,
    place_order = NULL,
    cancel_order = NULL,
    close_position = NULL,
    check_order = NULL,
    check_order_pending = NULL,
    load_okxr = function() {
      #---- fetch market data ----
      self$get_mark_price <- private$wrap_okx(okxr::get_public_mark_price)
      self$get_candles_okx <- private$wrap_okx(okxr::get_market_candles)
      self$get_history_candles_okx <- private$wrap_okx(okxr::get_market_history_candles)

      #---- get account data ----
      self$get_asset_balances <- private$wrap_okx(okxr::get_asset_balances)
      self$get_account_balance <- private$wrap_okx(okxr::get_account_balance)
      self$get_account_leverage_info <- private$wrap_okx(okxr::get_account_leverage_info)
      self$get_account_positions <- private$wrap_okx(okxr::get_account_positions)

      #---- set leverage ----
      self$set_leverage <- private$wrap_okx(okxr::post_account_set_leverage)

      #---- place, cancel, and close orders ----
      self$place_order <- private$wrap_okx(
        okxr::post_trade_order,
        post = function(res) self$mind_state$order_ids <- c(res$ordId, self$mind_state$order_ids)
      )
      self$cancel_order <- private$wrap_okx(okxr::post_trade_cancel_order)
      self$close_position <- private$wrap_okx(okxr::post_trade_close_position)

      #---- check orders ----
      self$check_order <- private$wrap_okx(okxr::get_trade_order)
      self$check_order_pending <- private$wrap_okx(okxr::gets_trade_orders_pending)
    },

    #' Set local path for OKX candle data
    #' @param dir Directory path
    set_okx_candle_dir = function(dir) {
      self$mind_state$okx_candle_dir <- dir
    },

    #' Get full RDS path for specific instrument and timeframe
    #' @param inst_id Instrument ID (e.g., ETH-USDT-SWAP)
    #' @param bar Timeframe (e.g., 1m, 4H)
    #' @return Full path to the RDS file
    get_okx_candle_rds_path = function(inst_id, bar) {
      sprintf("%s/%s_%s.rds", self$mind_state$okx_candle_dir, inst_id, bar)
    },

    #' Set CDD backtest directory
    #' @param dir Path to backtest directory
    set_cdd_bt_dir = function(dir) {
      self$mind_state$cdd_bt_dir <- dir
    },

    #' Get CDD backtest directory
    #' @return Directory path as string
    get_cdd_bt_dir = function() {
      self$mind_state$cdd_bt_dir
    },

    #' Load OHLCV data from local RDS file
    #' @param inst_id Instrument ID
    #' @param bar Timeframe
    #' @return A data.frame of OHLCV data
    load_candles = function(inst_id, bar) {
      .safe_read_rds(self$get_okx_candle_rds_path(inst_id, bar))
    },

    #' Sync new OHLCV data and save to RDS
    #' @param df_new New OHLCV data
    #' @param inst_id Instrument ID
    #' @param bar Timeframe
    sync_and_save_candles = function(df_new, inst_id, bar) {
      sync_and_save_candles(df_new, self$get_okx_candle_rds_path(inst_id, bar))
    },

    #' Rename OHLCV columns from OKX format
    rename_ohlcv_from_okx = function(...) okxr::standardize_ohlcv_names(...),

    #' Detect time gaps in OHLCV data
    detect_time_gaps = detect_time_gaps,

    #' Load CDD backtest summary and sort by performance
    #' @return A sorted data.frame with backtest results
    load_bt_summary = function() {
      log_data <- read.delim(paste0(self$get_cdd_bt_dir(), "/run_log.tsv"), sep = "\t", header = TRUE, stringsAsFactors = FALSE)
      log_data <- log_data[order(-log_data$ann_ret, log_data$max_drawdown), ]
      log_data
    },

    #' Open equity curve plot from backtest result
    view_bt_equity_curve = function(inst_id, strategy) system(sprintf("open %s/equity_curve_%s_%s.png", self$get_cdd_bt_dir(), inst_id, strategy)),

    #' Open monthly return chart from backtest result
    view_bt_monthly_chart = function(inst_id, strategy) system(sprintf("open %s/monthly_return_chart_%s_%s.png", self$get_cdd_bt_dir(), inst_id, strategy)),

    #' Open text-based stats from backtest result
    view_bt_stats = function(inst_id, strategy) system(sprintf("open %s/stats_%s_%s.txt", self$get_cdd_bt_dir(), inst_id, strategy))
  ),
  private = list(
    #' Internal wrapper for OKX functions with optional pre- and post-processing
    #' @param f The function to wrap
    #' @param pre Optional function to run before `f(...)`
    #' @param post Optional function to run on result
    wrap_okx = function(f, pre = NULL, post = NULL) {
      force(f)
      function(..., tz = self$mind_state$timezone, config = self$mind_state$tool_config$okx) {
        if (!is.null(pre)) pre(...)
        res <- f(..., tz = tz, config = config)
        if (!is.null(post)) post(res)
        return(res)
      }
    }
  )
)
