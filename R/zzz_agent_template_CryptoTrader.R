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

    # latest updated time should use the the last confirm time (which is the opening time) + 4 hours
    # still need to check whether there is updated public data
    # I think it is better to let more than one strategy-generated order compete
    # every time only choose one order (if tp/sl is chosen, there will be one turn stop, which looks like also ok)
    # tp/sl usually has high priority score based on a high weight (more nuanced weight need the confidence score of each strategy and its performance)
    # so each strategy has their own parameters
    # other strategy's priority based on a fixed weight of last year annret, max drawback, and win rate
    # when you do simulating, I think it is almost the same; just the mock orders will go to a paper trading system
    # when you do backtesting, it may be a bit different; the reason is to speed up calculating (maybe the lagged time setting could be different)
    # trading portfolio here is not buy-and-hold portfolio; it is a kind of strategy, referring to multiple asset signals
    
    init_values = function() {
      inst_id <- 'SOL-USDT-SWAP'
      bar <- '4H'
      bar_duration <- switch(bar, '4H'=240*60, '15m'=15*60)
      self$mind_state$order_ids <- character(0)
      self$mind_state$inst_id <- inst_id
      self$mind_state$bar <- bar
      self$mind_state$bar_duration <- bar_duration
      if (is.null(self$get_update_time(inst_id, bar))) self$update_new_candles(inst_id, bar)
      if (is.null(self$mind_state$public_info)) self$update_public_info(inst_id, bar, if_calculate_pivote_zone = TRUE)
      if (is.null(self$mind_state$trade_state)) self$update_trade_state()
    },
    
    run = function() {
      inst_id <- self$mind_state$inst_id
      bar <- self$mind_state$bar
      trade_state <- self$mind_state$trade_state
      self$update_price_info(inst_id)
      public_info <- self$mind_state$public_info
      trade_pars <- self$mind_state$trade_pars
      trade_strategy <- trade_pars$strategy
      need_pivote_zone <- FALSE
      update_time <- self$get_update_time(inst_id, bar)
      seconds_since_update <- as.numeric(Sys.time()) -  as.numeric(update_time)
          
      self$cancel_orders(inst_id)
      
      # we need to define tp sl separately based on last trading strategy type
      orders <- strategyr::generate_tp_sl_orders(trade_state, public_info, trade_pars)
      if (nrow(orders) <= 0 ) {
        if (seconds_since_update >= 2*self$mind_state$bar_duration) {
          if (self$update_new_candles(inst_id, bar)) {
            self$update_public_info(inst_id, bar, if_calculate_pivote_zone = need_pivote_zone)
            orders <- trade_strategy(trade_state, public_info, trade_pars)
          }
        }
      }
      
      if (nrow(orders) > 0) {
        for (i in 1:nrow(orders)) {
          order <- orders[i, ]
          
          if (order$trade_reason %in% c('breakout_1_long', 'breakout_1_short')) {
            self$mind_state$trade_pars$risk_TP <- 0.15
            self$mind_state$trade_pars$risk_SL <- -0.065
          } else if (order$trade_reason %in% c('breakout_2_long', 'breakout_2_short')) {
            self$mind_state$trade_pars$risk_TP <- 0.1
            self$mind_state$trade_pars$risk_SL <- -0.04
          } else if (order$trade_reason %in% c('breakout_3_long', 'breakout_3_short')) {
            self$mind_state$trade_pars$risk_TP <- 0.04
            self$mind_state$trade_pars$risk_SL <- -0.02
          } else if (order$trade_reason %in% c('breakout_4_long', 'breakout_4_short')) {
            self$mind_state$trade_pars$risk_TP <- 0.03
            self$mind_state$trade_pars$risk_SL <- -0.02
          } else if (order$trade_reason %in% c('zone_sniper_long', 'zone_sniper_short')) {
            self$mind_state$trade_pars$risk_TP <- 0.03
            self$mind_state$trade_pars$risk_SL <- -0.015
          } else if (order$trade_reason %in% c('zone_sniper_long_pivot', 'zone_sniper_short_pivot')) {
            self$mind_state$trade_pars$risk_TP <- 0.03
            self$mind_state$trade_pars$risk_SL <- -0.015
          }
          
          self$place_order(list(
            inst_id = inst_id,
            td_mode = "cross",
            side = ifelse(order$type == 'OPEN', 'buy', 'sell'),
            pos_side = order$pos,
            ord_type = "market",
            sz = order$size
          ))
        }
      }
    },

    # ... Arguments passed to parent `XAgent`
    initialize = function(...) {
      super$initialize(...)
      
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

    # Load OKX wrapper functions into agent methods
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

    #---- Candle Data ----
    
    # Set local path for OKX candle data
    set_okx_candle_dir = function(dir) {
      self$mind_state$okx_candle_dir <- dir
    },

    # Get full RDS path for specific instrument and timeframe
    get_okx_candle_rds_path = function(inst_id, bar) {
      sprintf("%s/%s_%s.rds", self$mind_state$okx_candle_dir, inst_id, bar)
    },

    # Load OHLCV data from local RDS file
    load_candles = function(inst_id, bar) {
      .safe_read_rds(self$get_okx_candle_rds_path(inst_id, bar))
    },

    # Sync new OHLCV data and save to RDS
    sync_and_save_candles = function(df_new, inst_id, bar) {
      sync_and_save_candles(df_new, self$get_okx_candle_rds_path(inst_id, bar))
    },

    # Detect time gaps in OHLCV data
    detect_time_gaps = detect_time_gaps,
    
    set_update_time = function(inst_id, bar, update_time) {
      if (is.null(self$mind_state$update_time[[inst_id]])) {
        self$mind_state$update_time[[inst_id]] <- list()
      }
      self$mind_state$update_time[[inst_id]][[bar]] <- update_time
    },
    get_update_time = function(inst_id, bar) self$mind_state$update_time[[inst_id]][[bar]],
    
    update_new_candles = function(inst_id, bar) {
      new_candles <- self$get_candles_okx(inst_id, bar)
      new_update_time <- max(new_candles[new_candles$confirm==1L,]$timestamp)
      old_update_time <- self$get_update_time(inst_id, bar)
      has_new <- self$sync_and_save_candles(new_candles, inst_id, bar)
      if (has_new || !identical(old_update_time, new_update_time)) {
        self$set_update_time(inst_id, bar, new_update_time)
        self$log(sprintf("Update new %s candle data of %s.", bar, inst_id))
      }
      return(has_new)
    },
    
    update_historical_candles = function(inst_id, bar, before_time) {
      new_candles <- self$get_history_candles_okx(inst_id, bar, before_time)
      has_new <- self$sync_and_save_candles(new_candles, inst_id, bar)
      if (has_new) {
        self$log(sprintf("Update historical %s candle data of %s before %s.", bar, inst_id, before_time))
      }
      return(has_new)
    },
    
    repair_missing_candles = function(inst_id, bar, candle_gaps, max_iter = 3) {
      for (i in 1:max_iter) {
        if (nrow(candle_gaps) <= 0) return(TRUE)
        before_time <- candle_gaps$to_time[1]
        self$update_historical_candles(inst_id, bar, before_time)
        candle_gaps <- agent$detect_time_gaps(agent$load_candles(inst_id, bar))
      }
      return(nrow(candle_gaps) <= 0)
    },
    
    backfill_candles = function(inst_id, bar) {
      candle_gaps <- self$detect_time_gaps(self$load_candles(inst_id, bar))
      if (nrow(candle_gaps) <= 0) {
        before_time <- min(self$load_candles(inst_id, bar)$timestamp)
      } else {
        before_time <- candle_gaps$to_time[1]
      }
      self$update_historical_candles(inst_id, bar, before_time)
    },
    
    #---- Trading ----
    
    set_trading_strategy = function(pars) self$mind_state$trade_pars <- pars,
    
    cancel_orders = function(inst_id) {
      pending_order_ids <- self$check_order_pending()$ordId
      if (length(pending_order_ids) > 0) {
        cancel_all_order_status <- do.call(rbind, lapply(pending_order_ids, function(order_id) {
          self$cancel_order(inst_id = inst_id, order_id)
        }))
      }
    },
    
    init_trade_state = function() {
      self$mind_state$trade_state$wallet_balance <- self$get_account_balance()$totalEq
      self$mind_state$trade_state$unrealized_pnl <- 0
      self$mind_state$trade_state$long_size <- 0
      self$mind_state$trade_state$avg_long_price <- 0
      self$mind_state$trade_state$short_size <- 0
      self$mind_state$trade_state$avg_short_price <- 0
    },
    
    update_trade_state = function() {
      self$init_trade_state()
      pos_now <- self$get_account_positions()
      if (!is.null(pos_now)) {
        self$mind_state$trade_state$unrealized_pnl <- pos_now$upl + pos_now$fee
        if(pos_now$posSide == 'long') {
          self$mind_state$trade_state$long_size <- pos_now$pos
          self$mind_state$trade_state$avg_long_price <- pos_now$avgPx
        } else if (pos_now$posSide == 'short') {
          self$mind_state$trade_state$short_size <- pos_now$pos
          self$mind_state$trade_state$avg_short_price <- pos_now$avgPx
        }
      }
    },
    
    update_price_info = function(inst_id) {
      self$mind_state$public_info$latest_close <- self$get_mark_price(inst_id)$markPx
    },
    update_public_info = function(inst_id, bar, ...) {
      self$mind_state$public_info <- tail(strategyr::calculate_technical_indicators(tail(self$load_candles(inst_id, bar), 60), ...), 1L)
    },
    
    #---- OKX backtesting ----
    
    #---- CDD backtesting ----
    
    # Set CDD backtest directory
    set_cdd_bt_dir = function(dir) {
      self$mind_state$cdd_bt_dir <- dir
    },

    # Get CDD backtest directory
    get_cdd_bt_dir = function() {
      self$mind_state$cdd_bt_dir
    },

    # Load CDD backtest summary and sort by performance
    load_bt_summary = function() {
      log_data <- read.delim(paste0(self$get_cdd_bt_dir(), "/run_log.tsv"), sep = "\t", header = TRUE, stringsAsFactors = FALSE)
      log_data <- log_data[order(-log_data$ann_ret, log_data$max_drawdown), ]
      log_data
    },

    # Open equity curve plot from backtest result
    view_bt_equity_curve = function(inst_id, strategy) system(sprintf("open %s/equity_curve_%s_%s.png", self$get_cdd_bt_dir(), inst_id, strategy)),

    # Open monthly return chart from backtest result
    view_bt_monthly_chart = function(inst_id, strategy) system(sprintf("open %s/monthly_return_chart_%s_%s.png", self$get_cdd_bt_dir(), inst_id, strategy)),

    # Open text-based stats from backtest result
    view_bt_stats = function(inst_id, strategy) system(sprintf("open %s/stats_%s_%s.txt", self$get_cdd_bt_dir(), inst_id, strategy))
  ),
  private = list(
    # Internal wrapper for OKX functions with optional pre- and post-processing
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
