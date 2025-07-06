#' Synchronize and Extract New Records from a Data Frame
#'
#' Given a new data frame and a key column, this function identifies and extracts rows
#' whose keys are not present in a set of previously known keys. It is typically used
#' to track updates from external sources (e.g., new chat messages, API responses).
#'
#' @param new_df A data frame containing new data, including a key column.
#' @param key_column A string specifying the column name in \code{new_df} used to identify unique records.
#' @param old_keys A character vector of previously seen keys. Defaults to \code{NULL} (assumes all rows are new).
#'
#' @return A list with the following components:
#' \describe{
#'   \item{\code{new_ids}}{A character vector of keys that were not in \code{old_keys}.}
#'   \item{\code{df}}{A data frame of new rows corresponding to \code{new_ids}.}
#'   \item{\code{has_new}}{Logical indicating whether any new records were found.}
#' }
#'
#' @examples
#' df_new <- data.frame(id = c("a", "b", "c"), value = 1:3)
#' util_sync_new_records(df_new, key_column = "id", old_keys = c("a"))
#'
#' @export
util_sync_new_records <- function(new_df, key_column, old_keys = NULL) {
  stopifnot(key_column %in% names(new_df))
  
  if (nrow(new_df) == 0) {
    return(list(
      new_ids = character(0),
      df = data.frame(),
      has_new = FALSE
    ))
  }
  
  new_keys <- as.character(new_df[[key_column]])

  # Identify new entries
  is_new <- if (is.null(old_keys)) rep(TRUE, length(new_keys)) else !(new_keys %in% old_keys)
  new_ids <- new_keys[is_new]
  new_rows <- new_df[is_new, , drop = FALSE]

  list(
    new_ids = new_ids,
    df = new_rows,
    has_new = length(new_ids) > 0
  )
}
