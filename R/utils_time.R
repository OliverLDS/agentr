.to_tz <- function(time, tz = Sys.timezone()) {
  as.POSIXct(format(time, tz = tz), tz = tz)
}

.fmt_ts <- function(ts) {
  format(ts, "%Y-%m-%d %H:%M:%S")
}

.is_recent <- function(last_ts = NULL, threshold_sec = 1800) {
  if (is.null(last_ts)) return(FALSE)
  diff <- difftime(Sys.time(), last_ts, units = "secs")
  as.numeric(diff) <= threshold_sec
}
