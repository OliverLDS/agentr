suppressPackageStartupMessages(library(agentr))

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (!length(args) || args[[1]] %in% c("-h", "--help", "help")) {
    print_help()
    return(invisible(0L))
  }

  cmd <- args[[1]]
  rest <- args[-1]
  if (length(rest) && rest[[1]] %in% c("-h", "--help")) {
    print_command_help(cmd)
    return(invisible(0L))
  }

  out <- switch(
    cmd,
    init = cmd_init(rest),
    "init-states" = cmd_init_states(rest),
    "build-initial-prompt" = cmd_build_initial_prompt(rest),
    "apply-initial-message" = cmd_apply_initial_message(rest),
    "build-revision-prompt" = cmd_build_revision_prompt(rest),
    "apply-revision-message" = cmd_apply_revision_message(rest),
    "apply-node-detail-message" = cmd_apply_node_detail_message(rest),
    "list-proposals" = cmd_list_proposals(rest),
    "approve-proposal" = cmd_approve_proposal(rest),
    "reject-proposal" = cmd_reject_proposal(rest),
    "export-review" = cmd_export_review(rest),
    "build-handoff" = cmd_build_handoff(rest),
    stop("Unknown command: ", cmd, call. = FALSE)
  )

  if (!is.null(out)) {
    print(out)
  }
  invisible(0L)
}

print_help <- function() {
  cat(
    "agentr CLI\n",
    "\n",
    "Usage:\n",
    "  Rscript agentr-cli.R <command> --workspace PATH [options]\n",
    "\n",
    "Commands:\n",
    "  init --workspace PATH [--comment TEXT_OR_FILE]\n",
    "  init-states --workspace PATH [--agent-spec PATH]\n",
    "  build-initial-prompt --workspace PATH --target TARGET --comment TEXT_OR_FILE [--out PATH]\n",
    "  apply-initial-message --workspace PATH --target TARGET --message RESPONSE_JSON [--comment TEXT_OR_FILE]\n",
    "  build-revision-prompt --workspace PATH --target TARGET --comment TEXT_OR_FILE [--node-id NODE_ID] [--out PATH]\n",
    "  apply-revision-message --workspace PATH --target TARGET --message RESPONSE_JSON [--node-id NODE_ID]\n",
    "  apply-node-detail-message --workspace PATH --node-id NODE_ID --message RESPONSE_JSON\n",
    "  list-proposals --workspace PATH --type TYPE [--status STATUS]\n",
    "  approve-proposal --workspace PATH --type TYPE --proposal-id ID [--note TEXT_OR_FILE]\n",
    "  reject-proposal --workspace PATH --type TYPE --proposal-id ID [--note TEXT_OR_FILE]\n",
    "  export-review --workspace PATH [--agent-spec PATH] [--out PATH] [--graph-layout grid|layered|swimlane|process] [--edge-style curved|straight|orthogonal]\n",
    "  build-handoff --workspace PATH [--out PATH]\n",
    "\n",
    "Targets: workflow, agent, memory, knowledge\n",
    "Types: workflow, agent, memory, knowledge\n",
    "\n",
    "This CLI builds prompts, applies constrained JSON responses, manages proposal states, and exports review/handoff artifacts. It does not execute an agent runtime.\n",
    sep = ""
  )
}

print_command_help <- function(cmd) {
  text <- switch(
    cmd,
    init = "init --workspace PATH [--comment TEXT_OR_FILE]\nCreate workspace directories and an optional README note.",
    "init-states" = "init-states --workspace PATH [--agent-spec PATH]\nCreate workflow, memory, knowledge, and scaffolder proposal states.",
    "build-initial-prompt" = "build-initial-prompt --workspace PATH --target TARGET --comment TEXT_OR_FILE [--out PATH]\nWrite an initial manual-LLM prompt.",
    "apply-initial-message" = "apply-initial-message --workspace PATH --target TARGET --message RESPONSE_JSON [--comment TEXT_OR_FILE]\nApply an initial constrained JSON response into proposal state.",
    "build-revision-prompt" = "build-revision-prompt --workspace PATH --target TARGET --comment TEXT_OR_FILE [--node-id NODE_ID] [--out PATH]\nWrite a revision prompt from current workspace state and human feedback. For workflow targets, --node-id builds a node-detail schema/nested-workflow prompt.",
    "apply-revision-message" = "apply-revision-message --workspace PATH --target TARGET --message RESPONSE_JSON [--node-id NODE_ID]\nApply a revision response. Workflow revisions are stored as proposals; --node-id constrains workflow revisions to node schema/nested workflow.",
    "apply-node-detail-message" = "apply-node-detail-message --workspace PATH --node-id NODE_ID --message RESPONSE_JSON\nApply node schema or nested-workflow response as a workflow proposal.",
    "list-proposals" = "list-proposals --workspace PATH --type TYPE [--status STATUS]\nList proposals in a workspace.",
    "approve-proposal" = "approve-proposal --workspace PATH --type TYPE --proposal-id ID [--note TEXT_OR_FILE]\nExplicitly approve a proposal and update approved state/spec artifacts.",
    "reject-proposal" = "reject-proposal --workspace PATH --type TYPE --proposal-id ID [--note TEXT_OR_FILE]\nReject a proposal without mutating approved specs.",
    "export-review" = "export-review --workspace PATH [--agent-spec PATH] [--out PATH] [--graph-layout grid|layered|swimlane|process] [--edge-style curved|straight|orthogonal]\nExport design-review HTML with available proposal states.",
    "build-handoff" = "build-handoff --workspace PATH [--out PATH]\nWrite an implementation handoff prompt from approved design artifacts.",
    "Unknown command."
  )
  cat(text, "\n", sep = "")
}

parse_cli_options <- function(args) {
  out <- list(options = list(), positionals = character())
  i <- 1L
  while (i <= length(args)) {
    item <- args[[i]]
    if (!startsWith(item, "--")) {
      out$positionals <- c(out$positionals, item)
      i <- i + 1L
      next
    }
    item <- substring(item, 3L)
    if (grepl("=", item, fixed = TRUE)) {
      pieces <- strsplit(item, "=", fixed = TRUE)[[1]]
      key <- pieces[[1]]
      value <- paste(pieces[-1], collapse = "=")
      out$options[[key]] <- normalize_optional_value(value)
      i <- i + 1L
      next
    }
    key <- item
    if (i == length(args) || startsWith(args[[i + 1L]], "--")) {
      out$options[[key]] <- TRUE
      i <- i + 1L
    } else {
      out$options[[key]] <- normalize_optional_value(args[[i + 1L]])
      i <- i + 2L
    }
  }
  out
}

normalize_optional_value <- function(value) {
  if (is.null(value)) {
    return(NULL)
  }
  if (identical(value, "NA") || identical(value, "NULL") || identical(value, "null")) {
    return(NULL)
  }
  value
}

command_option <- function(args, name, default = NULL, required = FALSE) {
  parsed <- parse_cli_options(args)
  value <- parsed$options[[name]]
  if (is.null(value)) {
    value <- default
  }
  if (isTRUE(required) && (is.null(value) || identical(value, TRUE) || !nzchar(as.character(value)[1]))) {
    stop("Missing required option `--", name, "`.", call. = FALSE)
  }
  value
}

cmd_init <- function(args) {
  workspace <- command_option(args, "workspace", required = TRUE)
  comment <- command_option(args, "comment")
  if (!is.null(comment)) {
    comment <- read_arg_text(comment)
  }
  paths <- init_agentr_workspace(workspace, comment = comment)
  paths$root
}

cmd_init_states <- function(args) {
  workspace <- command_option(args, "workspace", required = TRUE)
  agent_spec <- command_option(args, "agent-spec")
  init_agentr_proposal_states(workspace, agent_spec_path = agent_spec)
  "proposal states initialized"
}

cmd_build_initial_prompt <- function(args) {
  build_initial_spec_prompt(
    command_option(args, "workspace", required = TRUE),
    target = command_option(args, "target", required = TRUE),
    comment = command_option(args, "comment", required = TRUE),
    out = command_option(args, "out")
  )
}

cmd_apply_initial_message <- function(args) {
  comment <- command_option(args, "comment")
  apply_initial_spec_message(
    command_option(args, "workspace", required = TRUE),
    target = command_option(args, "target", required = TRUE),
    message = command_option(args, "message", required = TRUE),
    comment = comment
  )
  "initial response applied"
}

cmd_build_revision_prompt <- function(args) {
  build_revision_prompt(
    command_option(args, "workspace", required = TRUE),
    target = command_option(args, "target", required = TRUE),
    comment = command_option(args, "comment", required = TRUE),
    out = command_option(args, "out"),
    node_id = command_option(args, "node-id")
  )
}

cmd_apply_revision_message <- function(args) {
  apply_revision_message(
    command_option(args, "workspace", required = TRUE),
    target = command_option(args, "target", required = TRUE),
    message = command_option(args, "message", required = TRUE),
    node_id = command_option(args, "node-id")
  )
  "revision response applied"
}

cmd_apply_node_detail_message <- function(args) {
  apply_node_detail_message(
    command_option(args, "workspace", required = TRUE),
    node_id = command_option(args, "node-id", required = TRUE),
    message = command_option(args, "message", required = TRUE)
  )
  "node detail response applied"
}

cmd_list_proposals <- function(args) {
  list_workspace_proposals(
    command_option(args, "workspace", required = TRUE),
    type = command_option(args, "type", required = TRUE),
    status = command_option(args, "status")
  )
}

cmd_approve_proposal <- function(args) {
  note <- command_option(args, "note")
  if (!is.null(note)) {
    note <- read_arg_text(note)
  }
  approve_workspace_proposal(
    command_option(args, "workspace", required = TRUE),
    type = command_option(args, "type", required = TRUE),
    proposal_id = command_option(args, "proposal-id", required = TRUE),
    note = note
  )
  "proposal approved"
}

cmd_reject_proposal <- function(args) {
  note <- command_option(args, "note")
  if (!is.null(note)) {
    note <- read_arg_text(note)
  }
  reject_workspace_proposal(
    command_option(args, "workspace", required = TRUE),
    type = command_option(args, "type", required = TRUE),
    proposal_id = command_option(args, "proposal-id", required = TRUE),
    note = note
  )
  "proposal rejected"
}

cmd_export_review <- function(args) {
  export_workspace_design_review(
    command_option(args, "workspace", required = TRUE),
    agent_spec_path = command_option(args, "agent-spec"),
    out = command_option(args, "out"),
    graph_layout = command_option(args, "graph-layout", default = "grid"),
    edge_style = command_option(args, "edge-style", default = "curved")
  )
}

cmd_build_handoff <- function(args) {
  build_workspace_implementation_prompt(
    command_option(args, "workspace", required = TRUE),
    out = command_option(args, "out")
  )
}

read_arg_text <- function(x) {
  expanded <- path.expand(x)
  if (file.exists(expanded)) {
    return(paste(readLines(expanded, warn = FALSE), collapse = "\n"))
  }
  x
}

tryCatch(
  main(),
  error = function(e) {
    message("Error: ", conditionMessage(e))
    quit(status = 1L)
  }
)
