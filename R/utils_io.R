#' Save agent memory to disk
#' @export
memory_store <- function(agent_name, memory, path = "memory/") {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
  saveRDS(memory, file = file.path(path, paste0(agent_name, "_memory.rds")))
}

#' Load agent memory from disk
#' @export
memory_load <- function(agent_name, path = "memory/") {
  file <- file.path(path, paste0(agent_name, "_memory.rds"))
  if (!file.exists(file)) {
    warning("No memory file found for agent: ", agent_name)
    return(NULL)
  }
  readRDS(file)
}

