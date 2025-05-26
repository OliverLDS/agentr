#' @title Fetch a paginated OHLC chunk from OKX
#' @description Downloads up to 100 bars and appends to local store.
#' @param memory Agent belief state.
#' @param external_inputs Optional, not used here.
#' @return Updated memory.
#' @export
policy_fetch_ohlc_chunk <- function(memory, external_inputs = NULL) {
  inst_id <- memory$params$inst_id
  bar <- memory$params$bar
  until_ts <- memory$params$until_ts %||% 0
  last_ts <- memory$last_ts %||% NULL

  df <- fetch_okx_ohlc(inst_id, bar, before = last_ts)
  if (nrow(df) == 0 || min(df$ts) <= until_ts) {
    memory$state <- "finished"
    log_info("📉 Finished fetching {inst_id} [{bar}]")
    return(memory)
  }

  # Append to RDS file
  fname <- file.path("data/ohlc_raw", paste0(inst_id, "_", bar, ".rds"))
  old <- if (file.exists(fname)) readRDS(fname) else data.frame()
  new <- unique(rbind(old, df))
  saveRDS(new, fname)

  memory$last_ts <- min(df$ts)
  memory$effort <- (memory$effort %||% 0) + 1
  memory
}
