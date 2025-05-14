#' Format timestamp for printing
#' @export
format_timestamp <- function(ts) {
  format(ts, "%Y-%m-%d %H:%M:%S")
}

#' Check if the last timestamp is recent (within threshold)
#' @export
recent_timestamp <- function(threshold_sec = 1800, last_ts = NULL) {
  if (is.null(last_ts)) return(FALSE)
  diff <- difftime(Sys.time(), last_ts, units = "secs")
  as.numeric(diff) <= threshold_sec
}


