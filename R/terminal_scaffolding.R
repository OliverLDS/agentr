#' Render markdown-like text for terminal output
#'
#' @param txt Character string.
#'
#' @return Rendered character string with ANSI styling.
#' @export
render_markdown_terminal <- function(txt) {
  if (!is.character(txt)) {
    warning("Non-character input to render_markdown_terminal(): ", typeof(txt))
  }
  lines <- strsplit(txt, "\n")[[1]]

  styled <- vapply(lines, function(line) {
    if (grepl("^(\\-\\-\\-|\\*\\*\\*|___)\\s*$", line)) {
      return(paste0(rep("-", 50), collapse = ""))
    }

    if (grepl("^#{1,6} ", line)) {
      level <- attr(regexpr("^#{1,6}", line), "match.length")
      text <- sub("^#{1,6}\\s*", "", line)

      if (level == 1) {
        return(paste0("\033[1m", toupper(text), "\033[0m"))
      }
      if (level == 2) {
        return(paste0("\033[1m", text, "\033[0m"))
      }
      if (level == 3) {
        return(paste0("\033[4m", text, "\033[0m"))
      }
      return(paste0("\033[36m", text, "\033[0m"))
    }

    line <- gsub("`([^`]+)`", "\033[7m\\1\033[0m", line, perl = TRUE)
    line <- gsub("\\*\\*([^*\\n][^*]*?[^*\\n])\\*\\*", "\033[1m\\1\033[0m", line, perl = TRUE)
    line <- gsub(
      "(?<!\\*)\\*(?!\\*)([^*\\n][^*]*?[^*\\n])\\*(?!\\*)",
      "\033[3m\\1\033[0m",
      line,
      perl = TRUE
    )
    line <- gsub(
      "(?<!_)_(?!_)([^_\\n][^_]*?[^_\\n])_(?!_)",
      "\033[3m\\1\033[0m",
      line,
      perl = TRUE
    )

    line
  }, FUN.VALUE = character(1))

  paste(styled, collapse = "\n")
}

#' Prompt for terminal input during scaffolding
#'
#' @param prompt Character string shown to the human.
#'
#' @return Character string entered by the user.
#' @export
terminal_scaffold_input <- function(prompt) {
  readline(prompt = paste0(render_markdown_terminal(prompt), "\n> "))
}

#' Ask for workflow-node completeness in the terminal
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param node_id Workflow node identifier.
#'
#' @return The human response string.
#' @export
terminal_ask_node_complete <- function(scaffolder, node_id) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  prompt <- scaffolder$ask_human_complete(node_id)
  terminal_scaffold_input(prompt$question)
}

#' Ask for workflow changes in the terminal
#'
#' @param scaffolder A [`Scaffolder`] instance.
#'
#' @return The human response string.
#' @export
terminal_ask_workflow_changes <- function(scaffolder) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  prompt <- scaffolder$ask_human_changes()
  terminal_scaffold_input(prompt$question)
}

#' Ask for a node-specific rule in the terminal
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param node_id Workflow node identifier.
#'
#' @return The human response string.
#' @export
terminal_ask_node_rule <- function(scaffolder, node_id) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  prompt <- scaffolder$ask_human_rule(node_id)
  terminal_scaffold_input(prompt$question)
}
