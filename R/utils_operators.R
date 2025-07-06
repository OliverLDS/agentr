#' Null-Coalescing Operator
#'
#' This infix operator returns the first argument if it is not \code{NULL}, otherwise it returns the second.
#' It is useful for providing default values in a concise and readable way.
#'
#' @param a The primary value to return if not \code{NULL}.
#' @param b The fallback value if \code{a} is \code{NULL}.
#'
#' @return Either \code{a} or \code{b}, depending on whether \code{a} is \code{NULL}.
#' @examples
#' NULL %||% "default"  # returns "default"
#' 5 %||% 10            # returns 5
#' @export
`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}
