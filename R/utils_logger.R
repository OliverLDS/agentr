#' @title Log info message
#' @export
log_info <- function(msg) {
  cat(sprintf("[INFO] %s | %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg))
}

#' @title Log warning message
#' @export
log_warn <- function(msg) {
  cat(sprintf("[WARN] %s | %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg))
}

#' @title Log error message
#' @export
log_error <- function(msg) {
  cat(sprintf("[ERROR] %s | %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg))
}
