#' @export
detect_time_gaps <- function(df, bar_hours = 4, tolerance = 0.01) {

  df <- df[order(as.numeric(df$timestamp)), ]
  ts_numeric <- as.numeric(df$timestamp)
  
  dt_hours <- diff(ts_numeric) / 3600
  expected_dt <- bar_hours
  gap_idx <- which(dt_hours > expected_dt * (1 + tolerance))
  
  if (length(gap_idx) == 0) {
    message("✅ No time gaps detected.")
    return(data.frame())
  }

  data.frame(
    gap_index     = gap_idx,
    from_time     = df$timestamp[gap_idx],
    to_time       = df$timestamp[gap_idx + 1],
    actual_hours  = dt_hours[gap_idx],
    expected_hours = expected_dt
  )
}

#' @export
sync_and_save_candles <- function(df_new, data_path) {
  df_new <- df_new[df_new$confirm==1L,]
  key_column <- "timestamp"
  
  if (!file.exists(data_path)) {
    df_new <- df_new[order(as.numeric(df_new$timestamp)), ] 
    .safe_save_rds(df_new, data_path)
    return(TRUE)
  } else {
    df_old <- .safe_read_rds(data_path)
    old_keys <- as.character(unique(df_old[[key_column]]))
    res <- util_sync_new_records(df_new, key_column, old_keys)
    if (res$has_new) {
      df_combined <- rbind(df_old, res$df)
      df_combined <- df_combined[order(as.numeric(df_combined[[key_column]])), ]
      .safe_save_rds(df_combined, data_path)
    }
    return(res$has_new)
  }
}