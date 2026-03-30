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

#' Capture free-form terminal feedback and record it in the scaffolder
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param prompt Character string shown to the human.
#' @param source Discussion source label.
#' @param node_id Optional workflow node identifier.
#'
#' @return A list containing the prompt and recorded response.
#' @export
terminal_discuss_task <- function(
  scaffolder,
  prompt = "Share feedback for the current task or workflow.",
  source = "human",
  node_id = NULL
) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  response <- terminal_scaffold_input(prompt)
  if (nzchar(trimws(response))) {
    scaffolder$discuss_task(
      feedback = response,
      source = source,
      node_id = node_id
    )
  }

  list(
    prompt = prompt,
    response = response
  )
}

#' Ask for workflow-node completeness in the terminal
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param node_id Workflow node identifier.
#'
#' @return A list containing the prompt and response.
#' @export
terminal_ask_node_complete <- function(scaffolder, node_id) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  prompt <- scaffolder$ask_human_complete(node_id)
  response <- terminal_scaffold_input(prompt$question)

  if (nzchar(trimws(response))) {
    scaffolder$discuss_task(response, source = "human", node_id = node_id)
    normalized <- tolower(trimws(response))
    if (normalized %in% c("y", "yes", "complete", "done")) {
      scaffolder$review_node(node_id, status = "approved", notes = response, complete = TRUE)
    }
    if (normalized %in% c("n", "no", "incomplete", "not yet")) {
      scaffolder$review_node(node_id, status = "needs_revision", notes = response, complete = FALSE)
    }
  }

  list(prompt = prompt, response = response)
}

#' Ask for workflow changes in the terminal
#'
#' @param scaffolder A [`Scaffolder`] instance.
#'
#' @return A list containing the prompt and response.
#' @export
terminal_ask_workflow_changes <- function(scaffolder) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  prompt <- scaffolder$ask_human_changes()
  response <- terminal_scaffold_input(prompt$question)
  if (nzchar(trimws(response))) {
    scaffolder$discuss_task(response, source = "human")
  }
  list(prompt = prompt, response = response)
}

#' Ask for a node-specific rule in the terminal
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param node_id Workflow node identifier.
#'
#' @return A list containing the prompt and response.
#' @export
terminal_ask_node_rule <- function(scaffolder, node_id) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  prompt <- scaffolder$ask_human_rule(node_id)
  response <- terminal_scaffold_input(prompt$question)
  if (nzchar(trimws(response))) {
    scaffolder$discuss_task(response, source = "human", node_id = node_id)
    scaffolder$edit_workflow(rule_specs = stats::setNames(list(response), node_id))
  }
  list(prompt = prompt, response = response)
}
