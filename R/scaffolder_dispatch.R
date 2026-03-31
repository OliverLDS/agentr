#' @keywords internal
.scaffolder_validate_message_action <- function(action, allowed_methods) {
  if (!is.list(action)) {
    stop("Each action must be a list.", call. = FALSE)
  }
  if (!is.character(action$method) || length(action$method) != 1L) {
    stop("Each action must contain a single `method` string.", call. = FALSE)
  }
  if (!(action$method %in% allowed_methods)) {
    stop("Unsupported scaffolder method: ", action$method, call. = FALSE)
  }
  if (is.null(action$args)) {
    action$args <- list()
  }
  if (!is.list(action$args)) {
    stop("Each action `args` field must be a list.", call. = FALSE)
  }

  .validate_scaffolder_action_args(action$method, action$args)
  action
}

#' @keywords internal
.scaffolder_dispatch_action <- function(scaffolder, method, args) {
  if (!is.function(scaffolder[[method]])) {
    stop("Scaffolder does not implement method: ", method, call. = FALSE)
  }

  .validate_scaffolder_action_refs(scaffolder, method, args)
  dispatch_args <- .normalize_dispatch_args(scaffolder, method, args)
  do.call(scaffolder[[method]], dispatch_args)
}

#' @keywords internal
.scaffolder_apply_message_actions <- function(
  scaffolder,
  actions,
  stop_on_error = TRUE
) {
  results <- vector("list", length(actions))
  human_prompts <- list()
  errors <- list()

  for (i in seq_along(actions)) {
    action <- actions[[i]]
    method <- action$method
    args <- action$args

    execution <- tryCatch({
      result <- .scaffolder_dispatch_action(scaffolder, method, args)
      list(ok = TRUE, result = result, error = NULL)
    }, error = function(e) {
      list(ok = FALSE, result = NULL, error = conditionMessage(e))
    })

    if (!execution$ok && isTRUE(stop_on_error)) {
      stop(execution$error, call. = FALSE)
    }

    results[[i]] <- list(
      index = i,
      method = method,
      args = args,
      status = if (execution$ok) "applied" else "error",
      result = execution$result,
      error = execution$error
    )

    if (execution$ok && method %in% c("ask_human_complete", "ask_human_changes", "ask_human_rule")) {
      human_prompts[[length(human_prompts) + 1L]] <- list(
        index = i,
        method = method,
        prompt = execution$result
      )
    }
    if (!execution$ok) {
      errors[[length(errors) + 1L]] <- list(
        index = i,
        method = method,
        error = execution$error
      )
    }
  }

  list(
    applied_actions = results,
    workflow_after = scaffolder$workflow_spec(),
    human_prompts = human_prompts,
    errors = errors
  )
}
