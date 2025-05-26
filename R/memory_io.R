#' @title Save agent memory to store
#' @param agent An xagent object.
#' @param dir Folder where memory should be saved.
#' @export
save_agent_memory <- function(agent, dir = "store") {
  path <- file.path(dir, paste0(agent$name, "_memory.rds"))
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  saveRDS(agent$memory, path)
  log_info("💾 Saved memory for {agent$name} to {path}")
}

#' @title Load memory for agent
#' @param name Agent name (without _memory.rds).
#' @param dir Folder to load from.
#' @return Memory list.
#' @export
load_agent_memory <- function(name, dir = "store") {
  path <- file.path(dir, paste0(name, "_memory.rds"))
  if (!file.exists(path)) stop("Memory file not found for agent: ", name)
  readRDS(path)
}
