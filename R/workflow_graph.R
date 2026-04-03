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

#' Render a workflow as Graphviz DOT or a DiagrammeR graph
#'
#' Converts a workflow specification into a Graphviz-friendly representation.
#'
#' @param x A workflow specification or a [`Scaffolder`] instance.
#' @param rankdir Graphviz rank direction, for example `"TB"` or `"LR"`.
#' @param as Output format: raw `"dot"` text or a `"diagrammer"` object.
#'
#' @return A Graphviz DOT string or a `DiagrammeR` graph object.
#' @export
render_workflow_graphviz <- function(x, rankdir = "TB", as = c("dot", "diagrammer")) {
  as <- match.arg(as)
  graph_data <- workflow_graph_data(x)

  escape_label <- function(text) {
    text <- gsub("\\\\", "\\\\\\\\", as.character(text))
    text <- gsub("\"", "\\\\\"", text, fixed = TRUE)
    text
  }

  node_lines <- vapply(seq_len(nrow(graph_data$vertices)), function(i) {
    node <- graph_data$vertices[i, , drop = FALSE]
    sprintf(
      '  "%s" [label="%s", shape=%s, style=filled, fillcolor="%s", color="%s"];',
      escape_label(node$id[[1]]),
      escape_label(node$node_label[[1]]),
      if (identical(node$node_shape[[1]], "square")) "box" else "ellipse",
      node$node_color[[1]],
      node$node_border[[1]]
    )
  }, character(1))

  edge_lines <- if (nrow(graph_data$edges)) {
    vapply(seq_len(nrow(graph_data$edges)), function(i) {
      edge <- graph_data$edges[i, , drop = FALSE]
      sprintf(
        '  "%s" -> "%s" [label="%s"];',
        escape_label(edge$from[[1]]),
        escape_label(edge$to[[1]]),
        escape_label(edge$edge_label[[1]])
      )
    }, character(1))
  } else {
    character()
  }

  dot <- paste(
    "digraph workflow {",
    paste0("  rankdir=", rankdir, ";"),
    "  node [fontname=\"Helvetica\"];",
    "  edge [fontname=\"Helvetica\"];",
    paste(node_lines, collapse = "\n"),
    paste(edge_lines, collapse = "\n"),
    "}",
    sep = "\n"
  )

  if (identical(as, "dot")) {
    return(dot)
  }
  if (!requireNamespace("DiagrammeR", quietly = TRUE)) {
    stop(
      "`render_workflow_graphviz(..., as = \"diagrammer\")` requires the `DiagrammeR` package.",
      call. = FALSE
    )
  }
  DiagrammeR::grViz(dot)
}

#' Plot a workflow graph with igraph
#'
#' Creates an `igraph` object from a workflow and draws it using a DAG-friendly
#' layout when available.
#'
#' @param x A workflow specification or a [`Scaffolder`] instance.
#' @param layout Layout method. Use `"sugiyama"` for layered DAG layout or
#'   `"tree"` for a simpler tree-like view.
#' @param show_edge_labels Whether to draw edge labels.
#' @param ... Additional arguments passed to [igraph::plot.igraph()].
#'
#' @return Invisibly returns a list with the `graph` and `layout`.
#' @export
plot_workflow_graph <- function(
  x,
  layout = c("sugiyama", "tree"),
  show_edge_labels = TRUE,
  ...
) {
  if (!requireNamespace("igraph", quietly = TRUE)) {
    stop("`plot_workflow_graph()` requires the `igraph` package.", call. = FALSE)
  }

  layout <- match.arg(layout)
  graph_data <- workflow_graph_data(x)
  g <- igraph::graph_from_data_frame(
    d = graph_data$edges,
    vertices = graph_data$vertices,
    directed = TRUE
  )

  graph_layout <- switch(
    layout,
    sugiyama = igraph::layout_with_sugiyama(g)$layout,
    tree = igraph::layout_as_tree(g)
  )

  igraph::plot.igraph(
    g,
    layout = graph_layout,
    vertex.label = igraph::V(g)$node_label,
    vertex.color = igraph::V(g)$node_color,
    vertex.shape = ifelse(igraph::V(g)$node_shape == "square", "square", "circle"),
    vertex.frame.color = igraph::V(g)$node_border,
    vertex.label.color = "#222222",
    edge.label = if (isTRUE(show_edge_labels)) igraph::E(g)$edge_label else NA,
    ...
  )

  invisible(list(
    graph = g,
    layout = graph_layout
  ))
}
