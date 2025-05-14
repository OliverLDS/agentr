#' Null coalescing operator: a %||% b
#'
#' Returns `a` if not null, otherwise `b`.
#' @export
`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}
