#' Create a prompt by combining structured inputs
#' @export
build_prompt_from_inputs <- function(...) {
  inputs <- list(...)
  paste(
    sapply(names(inputs), function(k) paste0(k, ": ", inputs[[k]])),
    collapse = "\n"
  )
}

#' Create a task-specific prompt using memory and goal
#' @export
combine_memory_and_goal <- function(memory, goal) {
  recent <- memory$insights
  task <- goal$task
  paste("Goal:", task, "\nRecent insight:\n", recent)
}


