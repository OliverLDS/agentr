.find_new_rows <- function(new_dt, key_column, old_keys = NULL) { # the reason we don't use unique(old_dt[, key_column]) here is we may sometimes need include additional elements into the list of not updating
  stopifnot(key_column %in% names(new_dt))
  
  if (nrow(new_dt) == 0L) {
    return(list(
      new_ids = NULL,
      new_rows = NULL,
      has_new = FALSE
    ))
  }
  
  if (is.null(old_keys)) {
    new_rows <- new_dt
  } else {
    old <- data.table::data.table(tmp = old_keys)
    setnames(old, "tmp", key_column)
    # anti-join: rows in new_dt whose key NOT in old
    new_rows <- new_dt[!old, on = key_column]
  }
  
  new_ids <- new_rows[[key_column]]

  list(
    new_ids = new_ids,
    new_rows = new_rows,
    has_new = length(new_ids) > 0L
  )
}


