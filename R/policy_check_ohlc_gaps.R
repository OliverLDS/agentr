#' @title Detect OHLC gaps and spawn fetcher agents
#' @description Looks at data file and registers child agent if coverage is missing.
#' @param memory Agent belief state.
#' @param external_inputs Optional trigger.
#' @return Updated memory.
#' @export
policy_check_ohlc_gaps <- function(memory, external_inputs = NULL) {
  inst_id <- memory$params$inst_id
  bar <- memory$params$bar
  path <- memory$params$data_path
  until_ts <- memory$params$backfill_until_ts %||% 0
  max_gap <- memory$params$max_gap_secs %||% 70

  if (!file.exists(path)) {
    log_warn("⛔ No data found for {inst_id} [{bar}] at {path}")
    memory$state <- "finished"
    return(memory)
  }

  df <- readRDS(path)
  df <- df[order(df$ts), ]
  gap_indices <- which(diff(df$ts) > max_gap)

  if (length(gap_indices) == 0) {
    log_info("✅ No gaps detected in {inst_id} [{bar}]")
    memory$state <- "finished"
    return(memory)
  }

  gap_start <- df$ts[gap_indices[1]]
  if (gap_start <= until_ts) {
    log_info("ℹ️ Gap detected before backfill target. Skipping spawn.")
    memory$state <- "finished"
    return(memory)
  }

  # Register child agent to fetch that chunk
  child_name <- paste0("fetch_", inst_id, "_", bar, "_", as.integer(Sys.time()))
  append_child_agent_to_yaml(list(
    name = child_name,
    schedule = 5,
    pipeline = list("policy_fetch_ohlc_chunk"),
    memory = list(
      params = list(inst_id = inst_id, bar = bar, until_ts = until_ts),
      last_ts = gap_start
    )
  ))

  log_info("🧵 Spawned child agent: {child_name}")
  memory$state <- "waiting"
  memory
}
