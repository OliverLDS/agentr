#' @keywords internal
.html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

#' @keywords internal
.design_review_payload <- function(x, ...) {
  if (inherits(x, "DesignReviewSpec")) {
    return(x$to_list())
  }
  build_design_review_data(x, ...)$to_list()
}

#' @keywords internal
.design_review_asset <- function(name) {
  path <- system.file("review", name, package = "agentr", mustWork = FALSE)
  if (!nzchar(path)) {
    path <- file.path("inst", "review", name)
  }
  if (!file.exists(path)) {
    stop("Missing design review asset: ", name, call. = FALSE)
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

#' Build standalone design-review HTML
#'
#' Creates a standalone, offline HTML/JavaScript review page from a design
#' review bundle or supported design object. The page is review-only: it renders
#' design artifacts and exports structured feedback JSON, but it does not run
#' workflow nodes, call LLM providers, or mutate saved R objects.
#'
#' @param x A [`DesignReviewSpec`] or any input accepted by
#'   [build_design_review_data()].
#' @param include_workflow Whether to render workflow graph information.
#' @param include_knowledge Whether to render narrative and graph-shaped knowledge.
#' @param include_memory_schema Whether to render memory/state/interface schema.
#' @param include_feedback_panel Whether to include the structured feedback
#'   form and JSON export controls.
#' @param self_contained Reserved for future asset handling. The current
#'   implementation is always self-contained and uses no remote resources.
#' @param title Optional page title.
#' @param graph_layout Workflow graph layout. `"grid"` preserves the original
#'   row/column placement; `"layered"` places nodes by DAG depth; `"swimlane"`
#'   groups nodes into responsibility lanes; `"process"` renders loop-heavy
#'   workflows as a vertical process spine with side branches.
#' @param edge_style Workflow edge routing style: `"straight"`, `"curved"`, or
#'   `"orthogonal"`.
#' @param node_color_theme Initial node-color theme: `"default"` uses
#'   human-gate, deterministic-automation, and external stochastic LLM
#'   categories. Parent nodes with nested workflows inherit the most
#'   restrictive descendant category in the default theme. `"subsystems"` uses
#'   subsystem tags such as `rwm`, `pg`, `ae`, `la`, and `iac` when available.
#' @param ... Additional arguments passed to [build_design_review_data()] when
#'   `x` is not already a [`DesignReviewSpec`].
#'
#' @return HTML string.
#' @export
design_review_html <- function(
  x,
  include_workflow = TRUE,
  include_knowledge = TRUE,
  include_memory_schema = TRUE,
  include_feedback_panel = TRUE,
  self_contained = TRUE,
  title = NULL,
  graph_layout = c("grid", "layered", "swimlane", "process"),
  edge_style = c("curved", "straight", "orthogonal"),
  node_color_theme = c("default", "subsystems"),
  ...
) {
  graph_layout <- match.arg(graph_layout)
  edge_style <- match.arg(edge_style)
  node_color_theme <- match.arg(node_color_theme)
  payload <- .design_review_payload(x, ...)
  validate_design_review_spec(payload)
  if (is.null(title)) {
    title <- paste("agentr design review:", payload$agent_name)
  }
  config <- list(
    include_workflow = isTRUE(include_workflow),
    include_knowledge = isTRUE(include_knowledge),
    include_memory_schema = isTRUE(include_memory_schema),
    include_feedback_panel = isTRUE(include_feedback_panel),
    graph_layout = graph_layout,
    edge_style = edge_style,
    node_color_theme = node_color_theme
  )
  payload_json <- jsonlite::toJSON(.preserve_spec_arrays(payload), auto_unbox = TRUE, null = "null", pretty = FALSE)
  config_json <- jsonlite::toJSON(config, auto_unbox = TRUE, null = "null", pretty = FALSE)

  css <- .design_review_asset("design_review.css")
  js <- .design_review_asset("design_review.js")

  paste(
    "<!doctype html>",
    '<html lang="en">',
    "<head>",
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    paste0("<title>", .html_escape(title), "</title>"),
    "<style>",
    css,
    "</style>",
    "</head>",
    "<body>",
    "<header>",
    paste0("<h1>", .html_escape(title), "</h1>"),
    '<div class="meta">Review-only artifact. Structured feedback must be imported back into R for validation before it affects any design object.</div>',
    "</header>",
    '<div class="wrap">',
    '<main class="main" id="main"></main>',
    '<div class="splitter" id="splitter" aria-hidden="true" title="Drag to resize panels"></div>',
    '<aside class="panel feedback" id="feedbackPanel"></aside>',
    "</div>",
    '<script id="agentr-review-data" type="application/json">',
    as.character(payload_json),
    "</script>",
    '<script id="agentr-review-config" type="application/json">',
    as.character(config_json),
    "</script>",
    "<script>",
    js,
    "</script>",
    "</body>",
    "</html>",
    sep = "\n"
  )
}

#' Export standalone design-review HTML
#'
#' @param x A [`DesignReviewSpec`] or any input accepted by
#'   [build_design_review_data()].
#' @param path Output HTML path.
#' @param ... Arguments passed to [design_review_html()].
#'
#' @return Invisibly returns the normalized output path.
#' @export
export_design_review_html <- function(x, path, ...) {
  html <- design_review_html(x, ...)
  writeLines(html, path, useBytes = TRUE)
  invisible(normalizePath(path, mustWork = FALSE))
}
