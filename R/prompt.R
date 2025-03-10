# Formats the message history into a structured prompt
format_prompt <- function(memory) {
  messages <- get_recent_messages(memory, 5)
  
  if (length(messages) == 0) return("User: ")

  formatted_prompt <- paste(
    sapply(messages, function(msg) paste0(msg$role, ": ", msg$content)),
    collapse = "\n"
  )
  
  paste0(formatted_prompt, "\nUser: ")
}

# Adds system instructions at the beginning of the prompt (if needed)
add_system_instruction <- function(memory, instruction) {
  if (length(memory$messages) == 0 || memory$messages[[1]]$role != "system") {
    memory <- add_message(memory, "system", instruction)
  }
  memory
}
