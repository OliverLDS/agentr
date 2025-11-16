.render_markdown_terminal <- function(txt) {
  if (!is.character(txt)) {
    warning("Non-character input to .render_markdown_terminal: ", typeof(txt))
  }
  lines <- strsplit(txt, "\n")[[1]]

  styled <- vapply(lines, function(line) {
    # Horizontal rule (---, ***, ___) on its own line
    if (grepl("^(\\-\\-\\-|\\*\\*\\*|___)\\s*$", line)) {
      return(paste0(rep("─", 50), collapse = ""))
    }

    # Headings: #, ##, ###, #### (we can map to different styles)
    if (grepl("^#{1,6} ", line)) {
      level <- attr(regexpr("^#{1,6}", line), "match.length")
      text <- sub("^#{1,6}\\s*", "", line)

      if (level == 1) {
        return(paste0("\033[1m", toupper(text), "\033[0m"))         # H1: bold + uppercase
      } else if (level == 2) {
        return(paste0("\033[1m", text, "\033[0m"))                  # H2: bold
      } else if (level == 3) {
        return(paste0("\033[4m", text, "\033[0m"))                  # H3: underline
      } else {
        return(paste0("\033[36m", text, "\033[0m"))                 # H4–H6: cyan
      }
    }

    # Inline code: `code`
    line <- gsub("`([^`]+)`", "\033[7m\\1\033[0m", line, perl = TRUE)

    # Bold: **text**
    line <- gsub("\\*\\*([^*\\n][^*]*?[^*\\n])\\*\\*", "\033[1m\\1\033[0m", line, perl = TRUE)

    # Italic with asterisks: *text* (not **)
    line <- gsub("(?<!\\*)\\*(?!\\*)([^*\\n][^*]*?[^*\\n])\\*(?!\\*)",
                 "\033[3m\\1\033[0m", line, perl = TRUE)

    # Italic with underscores: _text_ (not __)
    line <- gsub("(?<!_)_(?!_)([^_\\n][^_]*?[^_\\n])_(?!_)",
                 "\033[3m\\1\033[0m", line, perl = TRUE)

    line
  }, FUN.VALUE = character(1))

  paste(styled, collapse = "\n")
}