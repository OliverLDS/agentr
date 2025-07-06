#' Convert Time to Specific Timezone
#'
#' Converts a POSIXct timestamp to the specified timezone while preserving the time structure.
#'
#' @param time A POSIXct timestamp.
#' @param tz A character string specifying the target timezone (e.g., "Asia/Singapore").
#'
#' @return A POSIXct timestamp adjusted to the specified timezone.
#' @export
convert_time_to_tz <- function(time, tz) {
  as.POSIXct(format(time, tz = tz), tz = tz)
}

#' Format a Timestamp to "YYYY-MM-DD HH:MM:SS"
#'
#' Converts a POSIXct timestamp to a readable character format.
#'
#' @param ts A POSIXct timestamp.
#'
#' @return A character string in the format \code{"YYYY-MM-DD HH:MM:SS"}.
#' @examples
#' format_timestamp(Sys.time())
#' @export
format_timestamp <- function(ts) {
  format(ts, "%Y-%m-%d %H:%M:%S")
}

#' Check if a Timestamp is Recent
#'
#' Determines whether a timestamp is within a threshold (in seconds) from the current time.
#'
#' @param threshold_sec A numeric threshold in seconds. Default is 1800 (30 minutes).
#' @param last_ts A POSIXct timestamp to check. If \code{NULL}, returns \code{FALSE}.
#'
#' @return Logical value indicating whether the timestamp is within the threshold.
#' @examples
#' recent_timestamp(600, Sys.time() - 300)  # TRUE
#' recent_timestamp(600, Sys.time() - 1000) # FALSE
#' @export
recent_timestamp <- function(threshold_sec = 1800, last_ts = NULL) {
  if (is.null(last_ts)) return(FALSE)
  diff <- difftime(Sys.time(), last_ts, units = "secs")
  as.numeric(diff) <= threshold_sec
}
