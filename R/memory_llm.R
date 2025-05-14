#' Create an empty LLM memory structure
#' @export
create_llm_memory <- function() {
  list(messages = list())
}

#' Add a message to LLM memory
#' @export
add_llm_message <- function(memory, role, content) {
  msg <- list(role = role, content = content)
  memory$messages <- c(memory$messages, list(msg))
  return(memory)
}

#' Get the N most recent messages from LLM memory
#' @export
get_recent_llm_messages <- function(memory, n = 5) {
  if (length(memory$messages) == 0) return(list())
  return(tail(memory$messages, n))
}

#' Format messages as a prompt string for LLM
#' @export
format_llm_prompt <- function(memory, n = 5) {
  msgs <- get_recent_llm_messages(memory, n)
  if (length(msgs) == 0) return("User: ")

  format_role <- function(role) {
    switch(tolower(role),
           user = "User",
           assistant = "Assistant",
           system = "System",
           tool = "Tool",
           role)
  }

  lines <- sapply(msgs, function(m) paste0(format_role(m$role), ": ", m$content))
  return(paste0(paste(lines, collapse = "\n"), "\nUser: "))
}

#' Ensure system instruction is at the top of memory
#' @export
add_system_instruction_if_missing <- function(memory, instruction) {
  if (length(memory$messages) == 0 || tolower(memory$messages[[1]]$role) != "system") {
    memory <- add_llm_message(memory, "system", instruction)
  }
  return(memory)
}
