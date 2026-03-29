#' Convert a workflow specification into graph-ready data
#'
#' Returns node and edge data frames in a shape that is directly usable by graph
#' packages such as `igraph::graph_from_data_frame()`.
#'
#' @param x A workflow specification or a [`Scaffolder`] instance.
#' @param highlight_low_confidence Whether to add a low-confidence flag based on
#'   `confidence_threshold`.
#' @param confidence_threshold Threshold for low-confidence highlighting.
#'
#' @return A list with `vertices` and `edges` data frames.
#' @export
workflow_graph_data <- function(
  x,
  highlight_low_confidence = TRUE,
  confidence_threshold = 0.6
) {
  if (inherits(x, "Scaffolder")) {
    x <- x$workflow_spec()
  }

  validate_workflow_spec(x)

  vertices <- x$nodes
  edges <- x$edges

  vertices$node_label <- vertices$label
  vertices$node_shape <- ifelse(vertices$human_required, "square", "circle")
  vertices$node_color <- ifelse(vertices$human_required, "#D55E00", "#0072B2")
  vertices$node_border <- ifelse(vertices$complete, "#009E73", "#666666")
  vertices$node_alpha <- ifelse(vertices$complete, 1, 0.85)
  if (highlight_low_confidence) {
    vertices$low_confidence <- is.na(vertices$confidence) | vertices$confidence < confidence_threshold
    vertices$node_color[vertices$low_confidence] <- "#CC79A7"
  }

  edges$edge_label <- edges$relation

  list(
    vertices = vertices,
    edges = edges
  )
}
