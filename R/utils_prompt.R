.sub_fixed_once <- function(pattern, replacement, x) {
  loc <- regexpr(pattern, x, fixed = TRUE)
  if (loc[1] == -1L) return(x)
  paste0(substr(x, 1L, loc[1]-1L), replacement,
         substr(x, loc[1] + attr(loc, "match.length"), nchar(x)))
}

.render_prompt <- function(template, args) {
  stopifnot(is.list(args))
  # find ordered tokens like %(foo)s or %(bar)d
  m <- gregexpr("%\\(([^)]+)\\)([sdifg])", template, perl = TRUE)
  reg <- regmatches(template, m)[[1]]
  if (length(reg) == 0L) return(template)
  tokens <- vapply(reg, function(x) sub("^%\\(([^)]+)\\).*$", "\\1", x), "")
  types  <- vapply(reg, function(x) sub("^.*\\)([sdifg])$", "\\1", x), "")
  # build ordered arg list
  vals <- lapply(tokens, function(k) {
    if (!length(args[[k]])) stop(sprintf("Missing variable: %s", k))
    args[[k]]
  })
  # replace named specifiers with %s/%d/%f...
  tmpl2 <- template
  for (i in seq_along(reg)) tmpl2 <- .sub_fixed_once(reg[i], paste0("%", types[i]), tmpl2)
  do.call(sprintf, c(tmpl2, vals))
}

.separate_chats <- function(agent_name, chat_DT, dialog_only = TRUE, 
  pretty = FALSE, auto_unbox = TRUE, na = "null") {
  if (dialog_only) {chat_DT <- chat_DT[type == 'dialog',]}
  chat_DT <- chat_DT[, .(role, msg)]
  n <- nrow(chat_DT)
  if (n == 0L) {
    return(list(
      unreplied_msg = "[]",
      replied_msg   = "[]"
    ))
  }
  idx <- which(chat_DT[["role"]] == agent_name)
  last_i <- if (length(idx)) idx[[length(idx)]] else 0L
  
  replied_DT   <- if (last_i > 0L) chat_DT[seq_len(last_i),] else NULL
  unreplied_DT <- if (last_i < n)  chat_DT[(last_i + 1L):n,] else NULL
  
  to_json_or_empty <- function(x) {
    if (is.null(x) || !nrow(x)) return("[]")
    jsonlite::toJSON(x, pretty = pretty, auto_unbox = auto_unbox, na = na)
  }
  
  list(
    unreplied_msg    = as.character(to_json_or_empty(unreplied_DT)),
    replied_msg      = as.character(to_json_or_empty(replied_DT))
  )
}
