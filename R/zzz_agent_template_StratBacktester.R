#' @export
StratBacktester <- R6::R6Class("StratBacktester",
  inherit = XAgent,
  public = list(
    #---- OKX backtesting ----
    
    #---- CDD backtesting ----
    
    # Set CDD backtest directory
    set_cdd_bt_dir = function(dir) {
      self$strat_backtester$cdd_bt_dir <- dir
    },

    # Get CDD backtest directory
    get_cdd_bt_dir = function() {
      self$strat_backtester$cdd_bt_dir
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
  )
)