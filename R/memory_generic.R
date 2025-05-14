#' Create empty generic memory
#' @export
create_memory <- function() {
  list()
}

#' Update memory by key
#' @export
update_memory <- function(memory, key, value) {
  memory[[key]] <- value
  return(memory)
}

#' Retrieve a memory field with fallback
#' @export
get_memory_field <- function(memory, key, default = NULL) {
  if (!is.null(memory[[key]])) return(memory[[key]])
  return(default)
}
