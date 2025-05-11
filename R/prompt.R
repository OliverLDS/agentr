# Format the LLM-style chat messages into a readable prompt string
format_llm_prompt <- function(memory, n = 5) {
  messages <- get_recent_llm_messages(memory, n)
  if (length(messages) == 0) return("User: ")

  format_role <- function(role) {
    switch(tolower(role),
           user = "User",
           assistant = "Assistant",
           system = "System",
           tool = "Tool",
           role)  # fallback if unknown
  }

  formatted <- sapply(messages, function(msg) {
    paste0(format_role(msg$role), ": ", msg$content)
  })

  paste0(paste(formatted, collapse = "\n"), "\nUser: ")
}


# Add system instruction if one does not already exist
add_system_instruction_if_missing <- function(memory, instruction) {
  if (length(memory$messages) == 0 || tolower(memory$messages[[1]]$role) != "system") {
    memory <- add_llm_message(memory, "system", instruction)
  }
  return(memory)
}


