#' @export
load_DataCollectorAgent <- function() {
  rlang::check_installed(c("okxr", "investdatar", "strategyr"),
                         reason = "to enable trading features.")
  config_fred_default <- list(
    api_key = Sys.getenv("FRED_API_KEY"),
    url = "https://api.stlouisfed.org/fred/series",
    mode = 'json'
  )
  config_okx_default <- list(
    api_key = Sys.getenv("OKX_API_KEY"),
    secret_key = Sys.getenv("OKX_SECRET_KEY"),
    passphrase = Sys.getenv("OKX_PASSPHRASE")
  )
  DataCollectorAgent <- R6::R6Class("DataCollectorAgent",
    inherit = Agent,
    public = list(
      
      data_collector = list(),
      
      initialize = function(..., config_fred = config_fred_default, config_okx = config_okx_default) {
        super$initialize(...)
        
        self$set_config('fred', config_fred)
        self$set_config('okx', config_okx)
        self$set_config('gemini')
        self$set_config('groq')
        self$set_config('email')
        
        wrap_fred <- function(f) {
          force(f)
          function(..., config=self$get_config('fred')) {
            f(..., config=config)
          }
        }
        self$data_collector$fred$data_path <- Sys.getenv('FRED_Data_Path')
        self$data_collector$fred$series_id_list <- c('FEDFUNDS', 'DFEDTARU', 'DFEDTARL', 'AMERIBOR', 'EFFR', 'SOFR', 'OBFR', 'DTB4WK', 'DTB1YR', 'TB3MS', 'DGS1MO', 'DGS3MO', 'DGS6MO', 'DGS1', 'DGS2', 'DGS3', 'DGS5', 'DGS7', 'DGS10', 'DGS20', 'DGS30', 'DBAA', 'BAMLH0A0HYM2', 'BAMLH0A3HYC', 'BAMLC0A4CBBB', 'BAMLH0A1HYBB', 'DFII10', 'T10Y2Y', 'T10Y3M', 'M2SL', 'BUSLOANS', 'TOTALSL', 'DEXCHUS', 'DEXJPUS', 'DEXMXUS', 'DEXINUS', 'DEXBZUS', 'DTWEXBGS', 'SP500', 'NASDAQCOM', 'STLFSI2', 'NFCI', 'TEDRATE', 'VIXCLS', 'T10YIE', 'T5YIE', 'T5YIFR', 'CPIAUCSL', 'CORESTICKM159SFRBATL', 'PCEPI', 'PCEPILFE', 'MEDCPIM158SFRBCLE', 'PPIACO', 'DCOILWTICO', 'DCOILBRENTEU', 'IR14270', 'PALLFNFINDEXQ', 'CSUSHPISA', 'USSTHPI', 'JTSJOL', 'PAYEMS', 'ICSA', 'CCSA', 'AHETPI', 'UNRATE', 'CES0500000003', 'CIVPART', 'GOLD', 'PERMIT', 'HOUST', 'EXHOSLUSM495S', 'GFDEGDQ188S', 'MTSDS133FMS', 'INDPRO', 'RSAFS', 'TCU', 'UMCSENT', 'USEPUINDXD', 'GDP', 'GDPC1')
        self$get_source_data_fred <- wrap_fred(investdatar::get_source_data_fred)
        self$get_source_utime_fred <- wrap_fred(investdatar::get_source_utime_fred)
        
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
        self$data_collector$okx_candle$data_path <- Sys.getenv('OKX_Candle_Data_Path')
        self$data_collector$okx_candle$inst_id_list <- c('BTC-USDT-SWAP', 'ETH-USDT-SWAP', 'SOL-USDT-SWAP', 'XRP-USDT-SWAP', 'BNB-USDT-SWAP')
        self$data_collector$okx_candle$bar_list <- c("4H")
        self$get_source_data_okx_candle <- wrap_okx(investdatar::get_source_data_okx_candle)
        self$get_source_hist_data_okx_candle <- wrap_okx(investdatar::get_source_hist_data_okx_candle)
        self$get_public_instruments <- wrap_okx(okxr::get_public_instruments)
        
        self$data_collector$ishare$ticker_list <- c(
          'DYNF', 'THRO', "BAI", "BDYN", "BDVL", # active ETFs
          'ITOT', 'IEFA', 'IEMG', 'EWJ', 'INDA', 'EZU', 'MCHI', 'EWY', 'EWT', 'EWZ', 'EWC', 'EWU', 'EWW', 'EWG', 'EWP', 'EWL', 'EWA', 'ECH', 'EWS', 'EWH', 'KSA', 'EWI', 'EZA', 'EIS', 'EPOL', 'EWQ', 'EWD', 'EWN', 'EWM', 'THD', 'EDEN', 'TUR', 'UAE', 'EWO', 'EPHE', 'KWT', 'QAT', 'ENZL', 'EIRL', 'ENOR', 'EFNL', 'EWK', # equity by regions
          'AGG', 'IAGG', # debt by regions
          'IVV', 'IVW', 'IVE', 'IJH', 'IJR', 'IWF', 'IWD', 'IWM', 'IWV', 'MTUM', # equity by factors
          'IBIT', 'ETHA', # crypto
          'IAU', 'SLV', 'TMET', # commodity
          'SGOV', 'IEF', 'SHY', 'TLT', 'IEI', 'TLH', # bond by duration
          'GOVT', 'MUB', 'MBB', 'LQD', 'HYG', # bond by credit
          'IYW', 'SOXX', 'ITA', 'IGF', 'IBB', 'IHI', 'IYF', 'IYR', 'IYH', 'IFRA', 'ITB', 'IDU', 'IYK', 'IYE', 'IHAK', 'IEO', 'IHF', 'IHE', 'IYT', 'IYZ', 'IAK', 'IEZ', 'VEGI', 'IBLC', 'IBAT', # equity by industry
          'REET', 'USRT'  # real estate
        )
      },
      
      run = function() {
        self$local_check_and_reply()
      },
      
      sync_data_with_source = function(key_col_name, local_file_path,
        new_dt, set_local_utime_func, set_local_utime_pars) {
        if (!file.exists(local_file_path)) {
          agentr:::.safe_save_rds(new_dt, local_file_path)
          do.call(set_local_utime_func, set_local_utime_pars)
          return(TRUE)
        } else {
          old_dt <- agentr:::.safe_read_rds(local_file_path)
          old_keys <- unique(old_dt[[key_col_name]])
          res <- agentr:::.find_new_rows(new_dt, key_col_name, old_keys)
          if (res$has_new) {
            new_dt <- rbindlist(list(old_dt, res$new_rows))
            agentr:::.safe_save_rds(new_dt, local_file_path)
            do.call(set_local_utime_func, set_local_utime_pars)
            return(TRUE)
          } else {
            do.call(set_local_utime_func, set_local_utime_pars)
            return(FALSE)
          }
        }
      },
      
      sync_data_with_source_timely = function(key_col_name, source_utime, local_utime, local_file_path,
        fetch_data_func, fetch_data_pars, set_local_utime_func, set_local_utime_pars) {
        if (is.null(local_utime)) local_utime <- as.POSIXct(-Inf)
        if (is.null(source_utime)) warning(sprintf("Source utime missing: %s.", local_file_path))
        if (source_utime > local_utime) {
          new_dt <- do.call(fetch_data_func, fetch_data_pars)
          res <- self$sync_data_with_source(key_col_name, local_file_path, new_dt, set_local_utime_func, set_local_utime_pars)
          if (res) {
            self$log(sprintf("Sync %s: %s.", 'timely', local_file_path))
            return(TRUE)
          }
        }
        return(FALSE)
      },
      
      #---- fred ----
      
      update_metadata_fred = function(series_id) {
        res <- investdatar::get_source_metadata_fred(series_id, self$get_config('fred'))
        self$data_collector$fred[[series_id]]$title <- res$title
        self$data_collector$fred[[series_id]]$start <- as.Date(res$start)
        self$data_collector$fred[[series_id]]$end <- as.Date(res$end)
        self$data_collector$fred[[series_id]]$freq <- res$freq
        self$data_collector$fred[[series_id]]$units <- res$units
        self$data_collector$fred[[series_id]]$season <- res$season
        invisible(NULL)
      },
      update_all_metadata_fred = function() {
        for (series_id in self$data_collector$fred$series_id_list) {
          self$update_metadata_fred(series_id)
        }
        invisible(NULL)
      },
      get_all_metadata_fred = function() {
        data.table::rbindlist({
          lapply(agent$data_collector$fred$series_id_list, function(id) {
            out <- agent$data_collector$fred[[id]]
            out$series_id <- id
            out
          })
        })
      },
      add_fred_series = function(series_id) {
        series_id_list <- self$data_collector$fred$series_id_list
        if (series_id %in% series_id_list) stop('You already had this series in list.')
        res <- investdatar::get_source_metadata_fred(series_id, self$get_config('fred'))
        if (is.null(res$title)) stop('Wrong fred id.')
        self$data_collector$fred$series_id_list <- c(series_id_list, series_id)
        self$update_metadata_fred(series_id)
        res <- self$sync_data_fred_timely(series_id)
        if (is.null(res)) stop('Errors in getting data.')
        self$data_collector$fred[[series_id]]$end <- max(self$get_local_data_fred(series_id)$date)
        invisible(NULL)
      },
      fill_local_utime_fred = function() {
        for (series_id in self$data_collector$fred$series_id_list) {
          if (is.null(self$get_local_utime_fred(series_id))) {
            self$data_collector$fred[[series_id]]$update_time <- as.POSIXct(max(self$get_local_data_fred(series_id)$date))
          }
        }
        invisible(NULL)
      },
      
      get_source_data_fred = NULL,
      get_source_utime_fred = NULL,
      get_folder_path_fred = function() self$data_collector$fred$data_path,
      get_file_path_fred = function(series_id) sprintf("%s/%s.rds", self$get_folder_path_fred(), series_id),
      get_local_data_fred = function(series_id) agentr:::.safe_read_rds(self$get_file_path_fred(series_id)),
      get_local_utime_fred = function(series_id) self$data_collector$fred[[series_id]]$update_time,
      set_local_utime_fred = function(series_id) {self$data_collector$fred[[series_id]]$update_time <- Sys.time(); invisible(NULL)},
      
      sync_data_fred_timely = function(series_id) {
        key_col_name <- 'date'
        source_utime <- self$get_source_utime_fred(series_id)
        local_utime <- self$get_local_utime_fred(series_id)
        local_file_path <- self$get_file_path_fred(series_id)
        fetch_data_func <- self$get_source_data_fred
        fetch_data_pars <- list(series_id = series_id)
        set_local_utime_func <- self$set_local_utime_fred
        set_local_utime_pars <- list(series_id = series_id)
        res <- self$sync_data_with_source_timely(key_col_name, source_utime, local_utime, local_file_path,
      fetch_data_func, fetch_data_pars, set_local_utime_func, set_local_utime_pars)
        invisible(res)
      },
      sync_all_data_fred_timely = function() {
        updated_series <- character(0L)
        for (series_id in self$data_collector$fred$series_id_list) {
          res <- self$sync_data_fred_timely(series_id)
          if (res) {
            self$data_collector$fred[[series_id]]$end <- max(self$get_local_data_fred(series_id)$date)
            updated_series <- c(updated_series, series_id)
          }
        }
        invisible(updated_series)
      },
      get_recent_updated_fred = function(detailed_mode = FALSE) {
        recent_series <- character(0L)
        for (series_id in self$data_collector$fred$series_id_list) {
          diff_days <- (difftime(Sys.time(), self$data_collector$fred[[series_id]]$end, 'days'))
          if (diff_days <=3) recent_series <- c(recent_series, series_id)
        }
        if (detailed_mode) {
          out <- data.table::rbindlist(
            lapply(recent_series, function(series_id) {
              list_out <- list()
              mega_info <- self$data_collector$fred[[series_id]]
              list_out$series_id <- series_id
              list_out$title <- mega_info$title
              list_out$units <- mega_info$units
              dt <- self$get_local_data_fred(series_id)
              list_out$previous_date <- dt[(.N-1), date]
              list_out$previous_value <- dt[(.N-1), value]
              list_out$latest_date <- dt[.N, date]
              list_out$latest_value <- dt[.N, value]
              list_out
            })
          )
          print(out)
          return(invisible(NULL))
        } else {
          return(invisible(recent_series))
        }
      },
      
      #---- ishare ----
      
      add_ishare_ticker = function(ticker) {
        ticker_list <- self$data_collector$ishare$ticker_list
        if (ticker %in% ticker_list) stop('You already had this ticker in list.')
        stopifnot(ticker %in% self$get_mega_data_ishare()$Ticker)
        self$data_collector$ishare$ticker_list <- c(ticker_list, ticker)
        invisible(NULL)
      },
      
      update_ishare_all_xls_file_names = function() {
        ticker_list <- self$data_collector$ishare$ticker_list
        mega_data_ishare <- self$get_mega_data_ishare()
        for (ticker in ticker_list) {
          prod_url <- mega_data_ishare[Ticker == ticker, etf_href]
          self$data_collector$ishare[[ticker]]$file_name <- investdatar:::.get_ishare_xls_file_name(prod_url)
        }
        invisible(NULL)
      },
      get_xls_file_name_ishare = function(ticker) {
        self$data_collector$ishare[[ticker]]$file_name
      },
      
      set_folder_path_ishare = function(folder_path) {self$data_collector$ishare$data_path <- folder_path; invisible(NULL)},
      get_folder_path_ishare = function() {self$data_collector$ishare$data_path},
      get_file_path_ishare = function(ticker) {
        stopifnot(ticker %in% self$data_collector$ishare$ticker_list)
        file.path(self$get_folder_path_ishare(), paste0(ticker, '_historical.rds'))
      },
      get_cache_dir_ishare = function() {file.path(self$get_folder_path_ishare(), '_cache')},
      get_file_path_mega_data_ishare = function() {file.path(self$get_folder_path_ishare(), 'mega_data.rds')},
      
      update_metadata_ishare = function(metadata_xls_path = file.path(self$get_cache_dir_ishare(), 'iShares-UnitedStates.xls')) {
        .safe_save_rds(investdatar:::.wraggle_mega_data(metadata_xls_path), self$get_file_path_mega_data_ishare())
        invisible(NULL)
      },
      get_mega_data_ishare = function() {.safe_read_rds(self$get_file_path_mega_data_ishare())},
      
      get_source_data_ishare = function(ticker) {
        stopifnot(ticker %in% self$data_collector$ishare$ticker_list)
        investdatar::get_source_data_ishare(ticker, 
          ishare_mega_data = self$get_mega_data_ishare(),
          cache_dir = self$get_cache_dir_ishare()
        )
      },
      update_source_utime_ishare = function() {
        source_utime <- investdatar::get_source_utime_ishare()
        stopifnot(!is.null(source_utime))
        self$data_collector$ishare$source_utime <- source_utime
      }, # this one is to fetch utime from webpage and store it locally
      get_source_utime_ishare = function() {self$data_collector$ishare$source_utime}, # this one is used for each ticker in a batch loop
      
      get_local_data_ishare = function(ticker) {
        stopifnot(ticker %in% self$data_collector$ishare$ticker_list)
        DT <- .safe_read_rds(self$get_file_path_ishare(ticker))
        data.table::setattr(DT, "ticker", ticker)
        data.table::setorder(DT, "date")
        data.table::setDT(DT)
        invisible(DT)
      },
      get_local_utime_ishare = function(ticker) {self$data_collector$ishare[[ticker]]$update_time},
      set_local_utime_ishare = function(ticker) {self$data_collector$ishare[[ticker]]$update_time <- Sys.time(); invisible(NULL)},
      
      sync_data_ishare_timely = function(ticker) {
        stopifnot(ticker %in% self$data_collector$ishare$ticker_list)
        key_col_name <- 'date'
        source_utime <- self$get_source_utime_ishare()
        local_utime <- self$get_local_utime_ishare(ticker)
        local_file_path <- self$get_file_path_ishare(ticker)
        fetch_data_func <- self$get_source_data_ishare
        fetch_data_pars <- list(ticker = ticker)
        set_local_utime_func <- self$set_local_utime_ishare
        set_local_utime_pars <- list(ticker = ticker)
        res <- self$sync_data_with_source_timely(key_col_name, source_utime, local_utime, local_file_path,
      fetch_data_func, fetch_data_pars, set_local_utime_func, set_local_utime_pars)
        invisible(res)
      },
      sync_all_data_ishare_timely = function(ticker_list = NULL, holding_update_list = c('DYNF', 'THRO', "BAI", "BDYN", "BDVL")) {
        self$update_source_utime_ishare()
        if (is.null(ticker_list)) ticker_list <- self$data_collector$ishare$ticker_list
        for (ticker in ticker_list) {
          self$sync_data_ishare_timely(ticker)
          # if (ticker %in% holding_update_list) self$sync_data_ishare_holdings(ticker)
          xls_file_name <- self$get_xls_file_name_ishare(ticker)
          cache_dir <- self$get_cache_dir_ishare()
          xls_file_path <- file.path(cache_dir, xls_file_name)
          file.remove(xls_file_path)
        }
        invisible(self)
      },
      
      sync_data_ishare_holdings = function(ticker_list = c('DYNF', 'THRO', "BAI", "BDYN", "BDVL")) {
        for (ticker in ticker_list) {
          stopifnot(ticker %in% self$data_collector$ishare$ticker_list)
          ishare_mega_data <- self$get_mega_data_ishare()
          prod_url <- ishare_mega_data[Ticker == ticker, etf_href]
          xls_file_name <- self$get_xls_file_name_ishare(ticker)
          cache_dir <- self$get_cache_dir_ishare()
          xls_file_path <- file.path(cache_dir, xls_file_name)
          invisible(investdatar:::.download_ishare_xls_file(prod_url, cache_dir = cache_dir))
          if (!file.exists(xls_file_path)) {message(sprintf('No file: %s', xls_file_path)); next}
          out <- investdatar:::.wraggle_holding_data(xls_file_path ) 
          holding_file_path <- file.path(self$get_folder_path_ishare(), paste0(ticker, '_holdings.rds'))
          if (file.exists(holding_file_path)) {
            holding_hist <- .safe_read_rds(holding_file_path)
          } else {
            holding_hist <- list()
          }
          holding_hist[[as.character(out$updated_date)]] <- out$holdings_dt
          .safe_save_rds(holding_hist, holding_file_path)
          file.remove(xls_file_path)
        }
        invisible(NULL)
      },
      get_local_data_ishare_holdings = function(ticker, date) {
        holding_file_path <- file.path(self$get_folder_path_ishare(), paste0(ticker, '_holdings.rds'))
        holding_hist <- .safe_read_rds(holding_file_path)
        holding_hist[[as.character(date)]]
      },
  
      #---- okx_candle ----
      
      get_source_data_okx_candle = NULL,
      get_source_hist_data_okx_candle = NULL,
      get_public_instruments = NULL,
      get_source_utime_okx_candle = function(bar) {investdatar::get_source_utime_okx_candle(bar, tz = self$get_tz())},
      get_folder_path_okx_candle = function() {self$data_collector$okx_candle$data_path},
      get_file_path_okx_candle = function(inst_id, bar) {sprintf("%s/%s_%s.rds", self$get_folder_path_okx_candle(), inst_id, bar)},
      get_local_data_okx_candle = function(inst_id, bar) {
        DT <- .safe_read_rds(self$get_file_path_okx_candle(inst_id, bar))
        data.table::setattr(DT, "inst_id", inst_id)
        data.table::setattr(DT, "bar", bar)
        data.table::setorder(DT, "datetime")
        data.table::setDT(DT)
        invisible(DT)
      },
      get_local_utime_okx_candle = function(inst_id, bar) {self$data_collector$okx_candle[[inst_id]][[bar]]$update_time},
      set_local_utime_okx_candle = function(inst_id, bar) {self$data_collector$okx_candle[[inst_id]][[bar]]$update_time <- Sys.time(); invisible(NULL)},
      
      sync_data_okx_candle_timely = function(inst_id, bar) {
        key_col_name <- 'datetime'
        source_utime <- self$get_source_utime_okx_candle(bar)
        local_utime <- self$get_local_utime_okx_candle(inst_id, bar)
        local_file_path <- self$get_file_path_okx_candle(inst_id, bar)
        fetch_data_func <- self$get_source_data_okx_candle
        fetch_data_pars <- list(inst_id = inst_id, bar = bar)
        set_local_utime_func <- self$set_local_utime_okx_candle
        set_local_utime_pars <- list(inst_id = inst_id, bar = bar)
        self$sync_data_with_source_timely(key_col_name, source_utime, local_utime, local_file_path,
        fetch_data_func, fetch_data_pars, set_local_utime_func, set_local_utime_pars)
        invisible(self)
      },
      sync_all_data_okx_candle_timely = function() {
        for (inst_id in self$data_collector$okx_candle$inst_id_list) {
          for (bar in self$data_collector$okx_candle$bar_list) {
            self$sync_data_okx_candle_timely(inst_id, bar)
          }
        }
        invisible(self)
      },
      
      sync_data_okx_candle_hist = function(inst_id, bar, before_time) {
        key_col_name <- 'datetime'
        local_file_path <- self$get_file_path_okx_candle(inst_id, bar)
        new_dt <- self$get_source_hist_data_okx_candle(inst_id = inst_id, bar = bar, before = before_time)
        if (is.null(new_dt)) return(invisible(NULL))
        set_local_utime_func <- self$set_local_utime_okx_candle
        set_local_utime_pars <- list(inst_id = inst_id, bar = bar)
        self$sync_data_with_source(key_col_name, local_file_path, new_dt, set_local_utime_func, set_local_utime_pars)
        invisible(self)
      },
      repair_backfill_data_okx_candle = function(inst_id, bar, max_iter = 3) {
        candle_gaps <- investdatar::detect_time_gaps_okx_candle(self$get_local_data_okx_candle(inst_id, bar))
        local_file_path <- self$get_file_path_okx_candle(inst_id, bar)
        for (i in 1:max_iter) {
          if (nrow(candle_gaps) > 0) {
            before_time <- candle_gaps$to_time[1]
            self$sync_data_okx_candle_hist(inst_id, bar, before_time)
            self$log(sprintf("Sync %s: %s.", 'repair', local_file_path))
            candle_gaps <- investdatar::detect_time_gaps_okx_candle(self$get_local_data_okx_candle(inst_id, bar))
          } else break
        }
        list_time <- self$get_public_instruments(inst_id)$listTime
        min_time <- min(self$get_local_data_okx_candle(inst_id, bar)$datetime)
        while(list_time < min_time) {
          res <- self$sync_data_okx_candle_hist(inst_id, bar, min_time)
          if (is.null(res)) return(invisible(self))
          min_time <- min(self$get_local_data_okx_candle(inst_id, bar)$datetime)
          Sys.sleep(1)
        }
        self$log(sprintf("Sync %s: %s.", 'backfill', local_file_path))
        invisible(self)
      },
      
      download_from_vm_okx_candle = function(inst_ids = self$data_collector$okx_candle$inst_id_list, bars = self$data_collector$okx_candle$bar_list, vm_name, vm_zone) {
        for (inst_id in inst_ids) {
          for (bar in bars) {
            investdatar::download_candle_from_vm(inst_id, bar, vm_name = vm_name, vm_zone = vm_zone)
          }
        }
      },
      upload_to_vm_okx_candle = function(inst_ids = self$data_collector$okx_candle$inst_id_list, bars = self$data_collector$okx_candle$bar_list, vm_name, vm_zone) {
        for (inst_id in inst_ids) {
          for (bar in bars) {
            investdatar::upload_candle_to_vm(inst_id, bar, vm_name = vm_name, vm_zone = vm_zone)
          }
        }
      }
      
    )
  )
  DataCollectorAgent
}


# agent <- NewsReaderAgent$new(name, mind_state)
# agent$mind_state$timezone('Asia/Hong_Kong')
# 
# agent$set_config('fred')
# agent$fetch_fred_series('GDP')

# okx package
# live backtesting should be different agent from trading agent (so their tasks will not messy)

