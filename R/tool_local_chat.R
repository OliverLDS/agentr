#' Append a Message to the Local Chat File
#'
#' Writes a time-stamped agent message to a plain text file used as a local chat interface.
#'
#' @param txt A character string representing the agent's response text.
#' @param agent_name The name of the agent (used in the message prefix).
#' @param chat_file_path Path to the local chat text file.
#'
#' @return No return value. Called for its side effect.
#' @export
send_text_local <- function(txt, agent_name, chat_file_path) {
      txt <- gsub("\n", "\\\\n", txt)
      msg <- sprintf("%s | %s: %s\n", Sys.time(), agent_name, txt)
      cat(msg, file = chat_file_path, append = TRUE)
    }

#' Open the Local Chat File in an Editor
#'
#' Opens the chat file using a text editor such as \code{textmate} or \code{micro}, with cursor positioned at the end.
#'
#' @param config A list with at least \code{chat_file} and optionally \code{editor}.
#'
#' @return No return value. The command is executed via \code{system()}.
#' @export
popout_local <- function(config) {
    chat_file <- config$chat_file
    editor    <- config$editor %||% "textmate"  # fallback to "textmate"
    lines <- readLines(chat_file, warn = FALSE)
    n_lines <- length(lines) + 1
    last_col <- nchar(tail(lines, 1)) + 1
    if (editor == 'textmate') {
      cmd <- sprintf("mate -l %d:%d %s", n_lines, last_col, shQuote(chat_file))
    } else if (editor == 'micro') { # micro has some problem here actually
      cmd <- sprintf("micro +%d %s", n_lines, shQuote(chat_file))
    }
    system(cmd)
}

#' Synchronize Local User Input from a Chat File
#'
#' Scans the local chat text file for new user replies (unformatted lines),
#' converts them into structured records, and reformats the file with timestamps.
#'
#' @param chat_file_path Path to the local chat text file.
#'
#' @return A list containing:
#' \describe{
#'   \item{\code{has_new}}{Logical. \code{TRUE} if new user input was found.}
#'   \item{\code{df}}{A data frame with new user messages (time, role, msg, channel).}
#' }
#'
#' @export
sync_local_user_input = function(chat_file_path) {
    lines <- readLines(chat_file_path, warn = FALSE)
    updated_lines <- character(length(lines))
    has_new <- FALSE
    df <- data.frame()
    
    for (i in seq_along(lines)) {
      line <- lines[i]
      if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \\|", line)) {
        # Agent message line; preserve as is
        updated_lines[i] <- line
      } else if (nzchar(trimws(line))) {
        # User reply line; record and replace
        has_new <- TRUE
        msg <- trimws(line)
        df <- data.frame(
          time      = Sys.time(),
          role      = "user",
          msg       = msg,
          channel   = "internal"
        )
        timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
        updated_lines[i] <- sprintf("%s | user: %s", timestamp, msg)
      } else {
        updated_lines[i] <- line  # blank line; preserve
      }
    }
  
    writeLines(updated_lines, chat_file_path)
    return(list(has_new = has_new, df = df))
  }
