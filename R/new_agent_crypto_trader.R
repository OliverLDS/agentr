#' @export
load_CryptoTraderAgent <- function() {
  rlang::check_installed(c("okxr", "investdatar", "strategyr"),
                         reason = "to enable trading features.")
  # Define the class *inside* the function, so no source-time deps:
  CryptoTraderAgent <- R6::R6Class(
    "CryptoTraderAgent",
    inherit = Agent,
    public = list(
      # declare placeholders (no pkg refs here):
      detect_time_gaps = NULL,
      
      get_mark_price = NULL,
      get_candles_okx = NULL,
      get_history_candles_okx = NULL,
      get_asset_balances = NULL,
      get_account_balance = NULL,
      get_account_leverage_info = NULL,
      get_account_positions = NULL,
      get_account_positions_history = NULL,
      set_leverage = NULL,
      place_order = NULL,
      cancel_order = NULL,
      close_position = NULL,
      check_order = NULL,
      check_order_pending = NULL,
      check_order_history_7d = NULL,
      
      initialize = function(..., config_okx) {
        super$initialize(...)
        
        self$set_config('okx', config_okx)

        wrap_okx <- function(f, pre=NULL, post=NULL) {
          force(f)
          function(..., tz=self$get_tz(), config=self$get_config('okx')) {
            if (!is.null(pre)) pre(...)
            res <- f(..., tz=tz, config=config)
            if (!is.null(post)) {
              pv <- post(res)
              if (!is.null(pv)) return(pv)
            }
            res
          }
        }
        self$get_mark_price                <- wrap_okx(okxr::get_public_mark_price)
        self$get_candles_okx               <- wrap_okx(okxr::get_market_candles)
        self$get_history_candles_okx       <- wrap_okx(okxr::get_market_history_candles)
        self$get_asset_balances            <- wrap_okx(okxr::get_asset_balances)
        self$get_account_balance           <- wrap_okx(okxr::get_account_balance)
        self$get_account_leverage_info     <- wrap_okx(okxr::get_account_leverage_info)
        self$get_account_positions         <- wrap_okx(okxr::get_account_positions)
        self$get_account_positions_history <- wrap_okx(okxr::get_account_positions_history)
        self$set_leverage                  <- wrap_okx(okxr::post_account_set_leverage)
        self$place_order                   <- wrap_okx(okxr::post_trade_order)
        self$cancel_order                  <- wrap_okx(okxr::post_trade_cancel_order)
        self$close_position                <- wrap_okx(okxr::post_trade_close_position)
        self$check_order                   <- wrap_okx(okxr::get_trade_order)
        self$check_order_pending           <- wrap_okx(okxr::get_trade_orders_pending)
        self$check_order_history_7d        <- wrap_okx(okxr::get_trade_orders_history_7d)

        
        # self$init_values()
      }
      # ...rest of your methods, but ensure all pkg calls are inside methods
      # and nothing references optional pkgs at class-definition time.
    )
  )
  CryptoTraderAgent
}





