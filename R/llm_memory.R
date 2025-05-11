# Create an empty memory structure
create_llm_memory <- function() {
  list(messages = list())
}

# Add a message to memory (returns updated memory)
add_llm_message <- function(memory, role, content) {
  if (!role %in% c("user", "assistant", "system", "tool")) {
    warning("Unrecognized role: ", role)
  }

  message <- list(role = role, content = content)
  memory$messages <- c(memory$messages, list(message))
  return(memory)
}

# Get the N most recent messages (for building context)
get_recent_llm_messages <- function(memory, n = 5) {
  messages <- memory$messages
  if (length(messages) == 0) return(list())
  return(tail(messages, n))
}

