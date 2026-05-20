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
    "  Rscript agentr-cli.R <command> [args]\n",
    "\n",
    "Commands:\n",
    "  init WORKSPACE [COMMENT_OR_FILE]\n",
    "  init-states WORKSPACE [AGENT_SPEC_RDS]\n",
    "  build-initial-prompt WORKSPACE TARGET COMMENT_OR_FILE [OUT]\n",
    "  apply-initial-message WORKSPACE TARGET RESPONSE_JSON [COMMENT_OR_FILE]\n",
    "  build-revision-prompt WORKSPACE TARGET COMMENT_OR_FILE [OUT]\n",
    "  apply-revision-message WORKSPACE TARGET RESPONSE_JSON\n",
    "  list-proposals WORKSPACE TYPE [STATUS]\n",
    "  approve-proposal WORKSPACE TYPE PROPOSAL_ID [NOTE_OR_FILE]\n",
    "  reject-proposal WORKSPACE TYPE PROPOSAL_ID [NOTE_OR_FILE]\n",
    "  export-review WORKSPACE [AGENT_SPEC_RDS] [OUT]\n",
    "  build-handoff WORKSPACE [OUT]\n",
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
    init = "init WORKSPACE [COMMENT_OR_FILE]\nCreate workspace directories and an optional README note.",
    "init-states" = "init-states WORKSPACE [AGENT_SPEC_RDS]\nCreate workflow, memory, knowledge, and scaffolder proposal states.",
    "build-initial-prompt" = "build-initial-prompt WORKSPACE TARGET COMMENT_OR_FILE [OUT]\nWrite an initial manual-LLM prompt.",
    "apply-initial-message" = "apply-initial-message WORKSPACE TARGET RESPONSE_JSON [COMMENT_OR_FILE]\nApply an initial constrained JSON response into proposal state.",
    "build-revision-prompt" = "build-revision-prompt WORKSPACE TARGET COMMENT_OR_FILE [OUT]\nWrite a revision prompt from current workspace state and human feedback.",
    "apply-revision-message" = "apply-revision-message WORKSPACE TARGET RESPONSE_JSON\nApply a revision response. Workflow revisions are stored as proposals.",
    "list-proposals" = "list-proposals WORKSPACE TYPE [STATUS]\nList proposals in a workspace.",
    "approve-proposal" = "approve-proposal WORKSPACE TYPE PROPOSAL_ID [NOTE_OR_FILE]\nExplicitly approve a proposal and update approved state/spec artifacts.",
    "reject-proposal" = "reject-proposal WORKSPACE TYPE PROPOSAL_ID [NOTE_OR_FILE]\nReject a proposal without mutating approved specs.",
    "export-review" = "export-review WORKSPACE [AGENT_SPEC_RDS] [OUT]\nExport design-review HTML with available proposal states.",
    "build-handoff" = "build-handoff WORKSPACE [OUT]\nWrite an implementation handoff prompt from approved design artifacts.",
    "Unknown command."
  )
  cat(text, "\n", sep = "")
}

need_args <- function(args, n, usage) {
  if (length(args) < n) {
    stop("Usage: ", usage, call. = FALSE)
  }
}

optional <- function(args, i, default = NULL) {
  if (length(args) >= i) {
    return(args[[i]])
  }
  default
}

cmd_init <- function(args) {
  need_args(args, 1, "init WORKSPACE [COMMENT_OR_FILE]")
  comment <- optional(args, 2)
  if (!is.null(comment)) {
    comment <- read_arg_text(comment)
  }
  paths <- init_agentr_workspace(args[[1]], comment = comment)
  paths$root
}

cmd_init_states <- function(args) {
  need_args(args, 1, "init-states WORKSPACE [AGENT_SPEC_RDS]")
  init_agentr_proposal_states(args[[1]], agent_spec_path = optional(args, 2))
  "proposal states initialized"
}

cmd_build_initial_prompt <- function(args) {
  need_args(args, 3, "build-initial-prompt WORKSPACE TARGET COMMENT_OR_FILE [OUT]")
  build_initial_spec_prompt(args[[1]], target = args[[2]], comment = args[[3]], out = optional(args, 4))
}

cmd_apply_initial_message <- function(args) {
  need_args(args, 3, "apply-initial-message WORKSPACE TARGET RESPONSE_JSON [COMMENT_OR_FILE]")
  comment <- optional(args, 4)
  apply_initial_spec_message(args[[1]], target = args[[2]], message = args[[3]], comment = comment)
  "initial response applied"
}

cmd_build_revision_prompt <- function(args) {
  need_args(args, 3, "build-revision-prompt WORKSPACE TARGET COMMENT_OR_FILE [OUT]")
  build_revision_prompt(args[[1]], target = args[[2]], comment = args[[3]], out = optional(args, 4))
}

cmd_apply_revision_message <- function(args) {
  need_args(args, 3, "apply-revision-message WORKSPACE TARGET RESPONSE_JSON")
  apply_revision_message(args[[1]], target = args[[2]], message = args[[3]])
  "revision response applied"
}

cmd_list_proposals <- function(args) {
  need_args(args, 2, "list-proposals WORKSPACE TYPE [STATUS]")
  list_workspace_proposals(args[[1]], type = args[[2]], status = optional(args, 3))
}

cmd_approve_proposal <- function(args) {
  need_args(args, 3, "approve-proposal WORKSPACE TYPE PROPOSAL_ID [NOTE_OR_FILE]")
  note <- optional(args, 4)
  if (!is.null(note)) {
    note <- read_arg_text(note)
  }
  approve_workspace_proposal(args[[1]], type = args[[2]], proposal_id = args[[3]], note = note)
  "proposal approved"
}

cmd_reject_proposal <- function(args) {
  need_args(args, 3, "reject-proposal WORKSPACE TYPE PROPOSAL_ID [NOTE_OR_FILE]")
  note <- optional(args, 4)
  if (!is.null(note)) {
    note <- read_arg_text(note)
  }
  reject_workspace_proposal(args[[1]], type = args[[2]], proposal_id = args[[3]], note = note)
  "proposal rejected"
}

cmd_export_review <- function(args) {
  need_args(args, 1, "export-review WORKSPACE [AGENT_SPEC_RDS] [OUT]")
  export_workspace_design_review(args[[1]], agent_spec_path = optional(args, 2), out = optional(args, 3))
}

cmd_build_handoff <- function(args) {
  need_args(args, 1, "build-handoff WORKSPACE [OUT]")
  build_workspace_implementation_prompt(args[[1]], out = optional(args, 2))
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
