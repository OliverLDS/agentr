#' Set a Value in a Nested List Structure
#'
#' Recursively updates a value in a nested list (or environment) using a vector of keys as the path.
#' This is useful for modifying deeply nested components of an agent's internal state, such as \code{mind_state}.
#'
#' @param obj A list (typically nested) in which to set the value.
#' @param path A character vector representing the path to the nested element (e.g., \code{c("history", "logs")}).
#' @param value The new value to assign at the specified path.
#'
#' @return The updated list with the new value inserted.
#'
#' @examples
#' state <- list(a = list(b = list(c = 1)))
#' state <- set_nested_path(state, c("a", "b", "c"), 42)
#' state$a$b$c  # Returns 42
#'
#' @export
set_nested_path <- function(obj, path, value) {
  if (length(path) == 1) {
    obj[[path]] <- value
  } else {
    obj[[path[[1]]]] <- Recall(obj[[path[[1]]]], path[-1], value)
  }
  return(obj)
}