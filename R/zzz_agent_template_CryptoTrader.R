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
    crypto_trader  = NULL,

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
    
    ensure_inst_slot = function(inst_id) {
      if (is.null(self$crypto_trader[[inst_id]])) {
        self$crypto_trader[[inst_id]] <- list(
          update_time = list(),
          trade_state = list(),
          trade_pars  = list(
            strategy = function(...) data.frame(),  # placeholder
            risk_TP = NA_real_,
            risk_SL = NA_real_
          ),
          public_info_tech = NULL,
          latest_close = NA_real_
        )
      }
    },
    
    init_values = function(LEVERAGE = 10) {
      self$set_config('okx')
      self$set_okx_candle_dir("~/Documents/2025/_2025-06-17_Crypto_Data/okx")
      self$crypto_trader$inst_ids <- c('SOL-USDT-SWAP', 'ETH-USDT-SWAP', 'BNB-USDT-SWAP')
      self$crypto_trader$bar <- '4H'
      durations <- c('4H' = 240*60, '15m' = 15*60)
      self$crypto_trader$bar_duration <- durations[self$crypto_trader$bar]
      
      inst_ids <- self$crypto_trader$inst_ids
      bar <- self$crypto_trader$bar
      
      self$update_eq()
      self$update_pos()
      for (inst_id in inst_ids) {
        self$ensure_inst_slot(inst_id)
        self$ensure_leverage(inst_id, LEVERAGE)
        self$update_new_candles(inst_id, bar)
        self$update_public_info_tech(inst_id, bar, if_calculate_pivote_zone = TRUE, if_calculate_arima = FALSE)
        self$update_price(inst_id)
        self$update_trade_state(inst_id)
      }
    },
    
    fetch_public_info = function(inst_id) {
      cbind(self$get_public_info_tech(inst_id), latest_close = self$get_price(inst_id))
    },
    
    evaluate_strat = function(inst_id) {
      bar <- self$crypto_trader$bar
      trade_state <- self$get_trade_state(inst_id)
      public_info <- self$fetch_public_info(inst_id)
      trade_pars <- self$get_trade_pars(inst_id)
      trade_strategy <- trade_pars$strategy
      orders <- trade_strategy(trade_state, public_info, trade_pars)
      orders
    },
    
    adjust_risk_level = function(inst_id, trade_reason) {
      if (trade_reason %in% c('breakout_layer1_long', 'breakout_layer1_short')) {
        self$set_trade_pars_tpsl(inst_id, 0.15, -0.065)
      } else if (trade_reason %in% c('breakout_layer2_long', 'breakout_layer2_short')) {
        self$set_trade_pars_tpsl(inst_id, 0.1, -0.04)
      } else if (trade_reason %in% c('breakout_layer3_long', 'breakout_layer3_short')) {
        self$set_trade_pars_tpsl(inst_id, 0.04, -0.02)
      } else if (trade_reason %in% c('breakout_layer4_long', 'breakout_layer4_short')) {
        self$set_trade_pars_tpsl(inst_id, 0.03, -0.02)
      } else if (trade_reason %in% c('zone_sniper_long', 'zone_sniper_short')) {
        self$set_trade_pars_tpsl(inst_id, 0.03, -0.015)
      } else if (trade_reason %in% c('zone_sniper_long_pivot', 'zone_sniper_short_pivot')) {
        self$set_trade_pars_tpsl(inst_id, 0.03, -0.015)
      }
    },
    
    append_order_record = function(order_record) {
      self$crypto_trader$order_df <- rbind(self$crypto_trader$order_df, order_record)
    },
    modify_order_record_status = function(order_id, new_status) {
      idx <- which(self$crypto_trader$order_df$order_id == order_id)
      if (length(idx) > 0) {
        self$crypto_trader$order_df$order_status[idx] <- new_status
        self$log(sprintf("Modify order status of %s to %s.", order_id, new_status))
      } else {
        self$log(sprintf("Order %s not found in record.", order_id))  
      }
    },
    
    wait_fill = function(inst_id, ord_id, timeout=30, poll=1) {
      t0 <- Sys.time()
      repeat {
        st <- try(self$check_order(inst_id, ord_id)$state, silent=TRUE)
        if (isTRUE(st == 'filled')) return(TRUE)
        if (difftime(Sys.time(), t0, units="secs") > timeout) return(FALSE)
        Sys.sleep(poll)
      }
    },
    
    # run logic: 
    # cancel all pedning orders
    # update price info
    # check tp/sl (execute if meet)
    # update tech info (check time first to reduce computing efforts)
    # place order
    # change tp/sl based on last order type
    
    run = function() {
      
      inst_ids <- self$crypto_trader$inst_ids
      bar <- self$crypto_trader$bar
      bar_duration <- self$crypto_trader$bar_duration
      
      for (inst_id in inst_ids) {
        
        #---- update trade state and pars ----
        trade_state <- self$get_trade_state(inst_id)
        trade_pars <- self$get_trade_pars(inst_id)
        trade_strategy <- trade_pars$strategy
        
        #---- update public info ----
        self$update_price(inst_id)
        seconds_since_update <- as.numeric(Sys.time()) -  as.numeric(self$get_update_time(inst_id, bar))
        if (seconds_since_update >= 2 * bar_duration) {
          self$update_new_candles(inst_id, bar)
          self$update_public_info_tech(inst_id, bar, if_calculate_pivote_zone = TRUE, if_calculate_arima = FALSE)
        }
        public_info <- self$fetch_public_info(inst_id)
        
        #---- cancel pending orders ---- 
        self$cancel_orders(inst_id)
        
        # ---- check tp/sl (execute if meet) ----
        orders <- strategyr::generate_tp_sl_orders(trade_state, public_info, trade_pars)
    
        if (nrow(orders) > 0) {
          for (i in 1:nrow(orders)) { # can not use 'for order in orders' here
            order <- orders[i, ]
            
            res <- self$place_order(
              inst_id = inst_id,
              td_mode = "cross",
              side = ifelse(order$type == 'OPEN', 'buy', 'sell'),
              pos_side = order$pos,
              ord_type = "market",
              sz = size
            )
            
            ord_id <- res$ordId
            
            if (is.null(ord_id)) {
              self$log("Order failed to place.")
              next
            } else {
              self$log(sprintf("Order %s placed.", ord_id))
            }
            order$order_id <- ord_id
            order$order_status <- 'live'
            order$inst_id <- inst_id
            self$append_order_record(order)
            
            filled <- self$wait_fill(inst_id, ord_id)
            if (filled) {
              self$modify_order_record_status(ord_id, 'filled')
            } else {
              self$log(sprintf("Order %s not filled within timeout.", ord_id))
            }
          }
        } else {
          orders <- trade_strategy(trade_state, public_info, trade_pars)
          
          if (nrow(orders) > 0) {
            for (i in 1:nrow(orders)) {
              order <- orders[i, ]
              
              if (inst_id == 'SOL-USDT-SWAP') {
                size <- round(order$size, 2)
              } else if (inst_id == 'BNB-USDT-SWAP') {
                size <- round(order$size*100, 2) # I don't know why, but for BNB, 1 is for 0.01
              } else if (inst_id == 'ETH-USDT-SWAP') {
                size <- round(order$size*10, 2) # and for ETH 1 is for 0.1 
              }
              
              if (size<=0) next
              
              res <- self$place_order(
                inst_id = inst_id,
                td_mode = "cross",
                side = ifelse(order$type == 'OPEN', 'buy', 'sell'),
                pos_side = order$pos,
                ord_type = "market",
                sz = size
              )
              
              print(list(
                inst_id = inst_id,
                td_mode = "cross",
                side = ifelse(order$type == 'OPEN', 'buy', 'sell'),
                pos_side = order$pos,
                ord_type = "market",
                sz = size
              ))
              
              ord_id <- res$ordId
              
              if (is.null(ord_id)) {
                self$log("Order failed to place.")
                next
              } else {
                self$log(sprintf("Order %s placed.", ord_id))
              }
              order$order_id <- ord_id
              order$order_status <- 'live'
              order$inst_id <- inst_id
              self$append_order_record(order)
              
              filled <- self$wait_fill(inst_id, ord_id)
              if (filled) {
                self$modify_order_record_status(ord_id, 'filled')
              } else {
                self$log(sprintf("Order %s not filled within timeout.", ord_id))
              }
              
              # there should be a step to check whether the order is filled.
              # only filled orders will change risk level
              # and the official tp/sl should be considered here
              
              trade_reason <- order$trade_reason
              self$adjust_risk_level(inst_id, trade_reason)
            }
          }
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
      self$place_order <- private$wrap_okx(okxr::post_trade_order)
      self$cancel_order <- private$wrap_okx(okxr::post_trade_cancel_order)
      self$close_position <- private$wrap_okx(okxr::post_trade_close_position)

      #---- check orders ----
      self$check_order <- private$wrap_okx(okxr::get_trade_order)
      self$check_order_pending <- private$wrap_okx(okxr::gets_trade_orders_pending)
      
      self$crypto_trader <- list(
        okx_candle_dir = NA_character_,
        order_df = data.frame(
          order_id = character(0),
          order_status = character(0),
          inst_id = character(0),
          type = character(0),
          pos = character(0),
          size = numeric(0),
          price = numeric(0),
          pricing_method = character(0),
          trade_reason = character(0)
        ),
        inst_ids = character(0),
        bar = NA_character_,
        bar_duration = NA_integer_
      )
      
      self$init_values()
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
    
    #---- Settings ----
    
    ensure_leverage = function(inst_id, lever) {
      if (any(self$get_account_leverage_info(inst_id = inst_id, mgn_mode = 'cross')$lever != lever)) {
        self$set_leverage(inst_id = inst_id, lever = lever, mgn_mode = 'cross')
        self$log(sprintf("Set leverage of %s as %d.", inst_id, lever))
      }
    },
    
    # Set local path for OKX candle data
    set_okx_candle_dir = function(dir) {
      self$crypto_trader$okx_candle_dir <- dir
    },

    # Get full RDS path for specific instrument and timeframe
    get_okx_candle_rds_path = function(inst_id, bar) {
      sprintf("%s/%s_%s.rds", self$crypto_trader$okx_candle_dir, inst_id, bar)
    },
    
    #---- Candle Data ----

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
      self$crypto_trader[[inst_id]]$update_time[[bar]] <- update_time
    },
    get_update_time = function(inst_id, bar) {
      self$crypto_trader[[inst_id]]$update_time[[bar]]
    },
    
    update_new_candles = function(inst_id, bar) {
      new_candles <- self$get_candles_okx(inst_id, bar)
      conf_rows <- new_candles[new_candles$confirm == 1L, "timestamp"]
      if (!length(conf_rows)) {
        self$log("No confirmed candles returned; skipping update_time.")
        return(FALSE)
      }
      new_update_time <- max(conf_rows)
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
        candle_gaps <- self$detect_time_gaps(self$load_candles(inst_id, bar))
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
    
    set_trade_pars = function(inst_id, pars) {
      self$crypto_trader[[inst_id]]$trade_pars <- pars
    },
    get_trade_pars = function(inst_id) {
      self$crypto_trader[[inst_id]]$trade_pars
    },
    
    set_trade_pars_tpsl = function(inst_id, risk_TP, risk_SL) {
      self$crypto_trader[[inst_id]]$trade_pars$risk_TP <- risk_TP
      self$log(sprintf("Set TP threshold of %s to %f.", inst_id, risk_TP))
      self$crypto_trader[[inst_id]]$trade_pars$risk_SL <- risk_SL
      self$log(sprintf("Set SL threshold of %s to %f.", inst_id, risk_SL))
    },
    
    cancel_orders = function(inst_id) {
      pending_orders <- self$check_order_pending()
      inst_orders <- pending_orders[pending_orders$instId == inst_id, ]
      for (order_id in inst_orders$ordId) {
        self$cancel_order(inst_id = inst_id, order_id = order_id)
        self$log(sprintf("Cancel %s's pending order %s.", inst_id, order_id))
      }
    },
    
    update_eq = function() {
      self$crypto_trader$eq <- self$get_account_balance()$totalEq
    },
    get_eq = function() {
      self$crypto_trader$eq
    },
    
    update_pos = function() {
      self$crypto_trader$pos <- self$get_account_positions()
    },
    get_pos = function() {
      self$crypto_trader$pos
    },
    
    init_trade_state = function(inst_id) {
      self$crypto_trader[[inst_id]]$trade_state$wallet_balance <- self$get_eq()
      self$crypto_trader[[inst_id]]$trade_state$unrealized_pnl <- 0
      self$crypto_trader[[inst_id]]$trade_state$long_size <- 0
      self$crypto_trader[[inst_id]]$trade_state$avg_long_price <- 0
      self$crypto_trader[[inst_id]]$trade_state$short_size <- 0
      self$crypto_trader[[inst_id]]$trade_state$avg_short_price <- 0
    },
    
    update_trade_state = function(inst_id) {
      self$init_trade_state(inst_id)
      pos_all <- self$get_pos()
      if (is.null(pos_all)) return(0)
      pos_now <- pos_all[pos_all$instId == inst_id, ]
      if (nrow(pos_now) > 0) {
        self$crypto_trader[[inst_id]]$trade_state$unrealized_pnl <- pos_now$upl + pos_now$fee
        if(pos_now$posSide == 'long') {
          self$crypto_trader[[inst_id]]$trade_state$long_size <- pos_now$pos
          self$crypto_trader[[inst_id]]$trade_state$avg_long_price <- pos_now$avgPx
        } else if (pos_now$posSide == 'short') {
          self$crypto_trader[[inst_id]]$trade_state$short_size <- pos_now$pos
          self$crypto_trader[[inst_id]]$trade_state$avg_short_price <- pos_now$avgPx
        }
      }
    },
    
    get_trade_state = function(inst_id) {
      self$crypto_trader[[inst_id]]$trade_state
    },
    
    update_price = function(inst_id) {
      self$crypto_trader[[inst_id]]$latest_close <- self$get_mark_price(inst_id)$markPx
    },
    get_price = function(inst_id) {
      self$crypto_trader[[inst_id]]$latest_close
    },
    update_public_info_tech = function(inst_id, bar, ...) {
      self$crypto_trader[[inst_id]]$public_info_tech <- tail(strategyr::calculate_technical_indicators(tail(self$load_candles(inst_id, bar), 60), ...), 1L)
    },
    get_public_info_tech = function(inst_id) {
      self$crypto_trader[[inst_id]]$public_info_tech
    }
    
  ),
  private = list(
    # Internal wrapper for OKX functions with optional pre- and post-processing
    wrap_okx = function(f, pre=NULL, post=NULL) {
      force(f)
      function(..., tz=self$get_tz(), config=self$get_config('okx')) {
        if (!is.null(pre)) pre(...)
        res <- f(..., tz=tz, config=config)
        if (!is.null(post)) {
          post_val <- post(res)
          if (!is.null(post_val)) return(post_val)
        }
        return(res)
      }
    }
  )
)
