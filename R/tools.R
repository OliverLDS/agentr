example_tool_terminate <- function(memory, ...) {
  list(memory = memory, output = "Terminating flow.")
}

example_tool_uppercase <- function(memory, input, ...) {
  transformed_text <- toupper(input)
  new_memory <- add_message(memory, "assistant", transformed_text)
  list(memory = new_memory, output = transformed_text)
}

TOOL_COLLECTION <- list(
  "terminate" = example_tool_terminate,
  "uppercase" = example_tool_uppercase
)
