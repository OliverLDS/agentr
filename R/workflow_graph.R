#' Convert a workflow specification into graph-ready data
#'
#' Returns node and edge data frames in a shape that is directly usable by graph
#' packages and renderers such as `DiagrammeR`.
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
  node_subsystems <- if (is.null(x$metadata$node_subsystems)) list() else x$metadata$node_subsystems
  subsystem_palette <- list(
    rwm = list(fill = "#E0F2FE", border = "#0369A1", label = "RWM: Reasoning & World Model"),
    pg = list(fill = "#DCFCE7", border = "#15803D", label = "PG: Perception & Grounding"),
    ae = list(fill = "#FDE68A", border = "#B45309", label = "AE: Action Execution"),
    la = list(fill = "#FCE7F3", border = "#BE185D", label = "LA: Learning & Adaptation"),
    iac = list(fill = "#EDE9FE", border = "#6D28D9", label = "IAC: Inter-Agent Communication")
  )

  vertices$node_label <- vertices$label
  vertices$node_shape <- ifelse(vertices$human_required, "diamond", "box")
  vertices$node_color <- ifelse(vertices$human_required, "#FDE68A", "#DBEAFE")
  vertices$node_border <- ifelse(vertices$human_required, "#B45309", "#1D4ED8")
  vertices$node_alpha <- ifelse(vertices$complete, 1, 0.85)
  vertices$node_subsystem <- vapply(vertices$id, function(id) {
    labels <- node_subsystems[[id]]
    if (is.null(labels) || !length(labels)) {
      return(NA_character_)
    }
    normalize_subsystem_key(labels)[1]
  }, character(1))
  for (name in names(subsystem_palette)) {
    idx <- which(vertices$node_subsystem == name)
    if (length(idx)) {
      vertices$node_color[idx] <- subsystem_palette[[name]]$fill
      vertices$node_border[idx] <- subsystem_palette[[name]]$border
    }
  }
  vertices$subsystem_label <- vapply(vertices$node_subsystem, function(x) {
    if (is.na(x) || is.null(subsystem_palette[[x]])) {
      return(NA_character_)
    }
    subsystem_palette[[x]]$label
  }, character(1))
  if (highlight_low_confidence) {
    vertices$low_confidence <- is.na(vertices$confidence) | vertices$confidence < confidence_threshold
    vertices$node_color[vertices$low_confidence] <- "#FBCFE8"
    vertices$node_border[vertices$low_confidence] <- "#BE185D"
  }

  edges$edge_label <- edges$relation

  list(
    vertices = vertices,
    edges = edges
  )
}

.dot_escape_string <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub("'", "&#39;", x, fixed = TRUE)
  gsub("\"", "\\\"", x, fixed = TRUE)
}

.dot_escape_multiline <- function(x) {
  placeholder <- "<<DOT_NEWLINE_PLACEHOLDER>>"
  x <- gsub("\n", placeholder, x, fixed = TRUE)
  x <- .dot_escape_string(x)
  gsub(placeholder, "\\n", x, fixed = TRUE)
}

.dot_escape_id <- function(x) {
  .dot_escape_string(x)
}

.dot_prepare_label <- function(x, width = 28) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- gsub("\r\n", "\n", x, fixed = TRUE)
  x <- gsub("\r", "\n", x, fixed = TRUE)
  x <- gsub("\\\\n", "\n", x)
  if (!grepl("\n", x, fixed = TRUE)) {
    x <- paste(strwrap(x, width = width), collapse = "\n")
  }
  .dot_escape_multiline(x)
}

.dot_present <- function(x) {
  !is.null(x) && length(x) == 1L && !is.na(x) && nzchar(as.character(x))
}

.workflow_node_tooltip <- function(nodes, i) {
  parts <- c(
    paste0("id: ", nodes$id[[i]]),
    if ("subsystem_label" %in% names(nodes) && .dot_present(nodes$subsystem_label[[i]])) paste0("subsystem: ", nodes$subsystem_label[[i]]) else NULL,
    if (!is.na(nodes$confidence[[i]])) paste0("confidence: ", sprintf("%.2f", nodes$confidence[[i]])) else NULL,
    if ("rule_spec" %in% names(nodes) && .dot_present(nodes$rule_spec[[i]])) paste0("rule: ", nodes$rule_spec[[i]]) else NULL,
    if ("implementation_hint" %in% names(nodes) && .dot_present(nodes$implementation_hint[[i]])) paste0("hint: ", nodes$implementation_hint[[i]]) else NULL,
    if ("review_status" %in% names(nodes) && .dot_present(nodes$review_status[[i]])) paste0("review_status: ", nodes$review_status[[i]]) else NULL,
    if ("review_notes" %in% names(nodes) && .dot_present(nodes$review_notes[[i]])) paste0("review: ", nodes$review_notes[[i]]) else NULL
  )
  x <- paste(parts, collapse = "\n")
  .dot_escape_multiline(x)
}

.workflow_edge_tooltip <- function(edges, i) {
  parts <- c(
    if ("relation" %in% names(edges) && .dot_present(edges$relation[[i]])) paste0("relation: ", edges$relation[[i]]) else NULL,
    if (!is.na(edges$confidence[[i]])) paste0("confidence: ", sprintf("%.2f", edges$confidence[[i]])) else NULL,
    if ("notes" %in% names(edges) && .dot_present(edges$notes[[i]])) paste0("notes: ", edges$notes[[i]]) else NULL
  )
  x <- paste(parts, collapse = "\n")
  .dot_escape_multiline(x)
}

.workflow_graph_dot <- function(
  graph_data,
  rankdir = "TB",
  label_width = 28,
  show_edge_labels = FALSE,
  show_tooltips = FALSE,
  same_rank = NULL
) {
  nodes <- graph_data$vertices
  edges <- graph_data$edges

  if (!"human_required" %in% names(nodes)) nodes$human_required <- FALSE
  if (!"confidence" %in% names(nodes)) nodes$confidence <- NA_real_
  if (!"relation" %in% names(edges)) edges$relation <- ""
  if (!"confidence" %in% names(edges)) edges$confidence <- NA_real_

  nodes$label_prepared <- vapply(nodes$node_label %||% nodes$label, .dot_prepare_label, character(1), width = label_width)
  nodes$shape <- ifelse(nodes$human_required, "diamond", "box")
  nodes$style <- ifelse(nodes$human_required, "filled", "rounded,filled")
  nodes$fillcolor <- nodes$node_color %||% ifelse(nodes$human_required, "#FDE68A", "#DBEAFE")
  nodes$color <- nodes$node_border %||% ifelse(nodes$human_required, "#B45309", "#1D4ED8")

  node_lines <- vapply(seq_len(nrow(nodes)), function(i) {
    tooltip_part <- if (isTRUE(show_tooltips)) {
      sprintf(', tooltip="%s"', .workflow_node_tooltip(nodes, i))
    } else {
      ""
    }
    paste0(
      sprintf(
        paste0(
          '  "%s" [',
          'label="%s", shape=%s, style="%s", fillcolor="%s", color="%s", ',
          'fontcolor="#111827", fontname="Helvetica", fontsize=11, ',
          'margin="0.18,0.10", penwidth=1.3'
        ),
        .dot_escape_id(nodes$id[[i]]),
        nodes$label_prepared[[i]],
        nodes$shape[[i]],
        nodes$style[[i]],
        nodes$fillcolor[[i]],
        nodes$color[[i]]
      ),
      tooltip_part,
      "];"
    )
  }, character(1))

  edge_lines <- if (nrow(edges)) {
    edge_color <- ifelse(edges$relation == "routes_to", "#2563EB", "#6B7280")
    edge_style <- ifelse(edges$relation == "routes_to", "dashed", "solid")
    edge_penwidth <- ifelse(is.na(edges$confidence), 1.2, pmax(1.0, 1 + 2 * (edges$confidence - 0.85)))

    vapply(seq_len(nrow(edges)), function(i) {
      edge_label <- if (isTRUE(show_edge_labels)) .dot_prepare_label(edges$relation[[i]], width = 100) else ""
      tooltip_part <- if (isTRUE(show_tooltips)) {
        sprintf(', tooltip="%s"', .workflow_edge_tooltip(edges, i))
      } else {
        ""
      }
      paste0(
        sprintf(
          paste0(
            '  "%s" -> "%s" [',
            'color="%s", style="%s", penwidth=%.2f, arrowsize=0.8, ',
            'label="%s", fontname="Helvetica", fontsize=9'
          ),
          .dot_escape_id(edges$from[[i]]),
          .dot_escape_id(edges$to[[i]]),
          edge_color[[i]],
          edge_style[[i]],
          edge_penwidth[[i]],
          edge_label
        ),
        tooltip_part,
        "];"
      )
    }, character(1))
  } else {
    character()
  }

  rank_lines <- character(0)
  if (!is.null(same_rank)) {
    if (!is.list(same_rank)) {
      stop("`same_rank` must be NULL or a list of character vectors.", call. = FALSE)
    }
    rank_lines <- vapply(same_rank, function(x) {
      sprintf(
        "  { rank = same; %s; }",
        paste(sprintf('"%s"', vapply(x, .dot_escape_id, character(1))), collapse = "; ")
      )
    }, character(1))
  }

  paste(
    "digraph workflow {",
    sprintf('  graph [layout=dot, rankdir=%s, nodesep=0.40, ranksep=0.65, splines=spline, pad=0.2];', rankdir),
    '  node [fontname="Helvetica"];',
    '  edge [fontname="Helvetica"];',
    paste(node_lines, collapse = "\n"),
    if (length(rank_lines)) paste(rank_lines, collapse = "\n") else "",
    paste(edge_lines, collapse = "\n"),
    "}",
    sep = "\n"
  )
}

#' Render a workflow as Graphviz DOT, DiagrammeR, or SVG
#'
#' Converts a workflow specification into a Graphviz-friendly representation.
#' The DiagrammeR path is preferred for visual inspection of workflow DAGs.
#'
#' @param x A workflow specification or a [`Scaffolder`] instance.
#' @param rankdir Graphviz rank direction, for example `"TB"` or `"LR"`.
#' @param as Output format: raw `"dot"` text, a `"diagrammer"` object, or
#'   exported `"svg"` text.
#' @param label_width Approximate wrapping width for node labels.
#' @param show_edge_labels Whether to show edge relation labels.
#' @param show_tooltips Whether to include Graphviz tooltip attributes. Defaults
#'   to `FALSE` because long prose tooltips can trigger Viz.js parse failures in
#'   some DiagrammeR renderers.
#' @param same_rank Optional list of node-id character vectors to keep at the
#'   same Graphviz rank.
#'
#' @return A Graphviz DOT string, `DiagrammeR` graph object, or SVG string.
#' @export
render_workflow_graphviz <- function(
  x,
  rankdir = "TB",
  as = c("dot", "diagrammer", "svg"),
  label_width = 28,
  show_edge_labels = FALSE,
  show_tooltips = FALSE,
  same_rank = NULL
) {
  as <- match.arg(as)
  graph_data <- workflow_graph_data(x)
  dot <- .workflow_graph_dot(
    graph_data = graph_data,
    rankdir = rankdir,
    label_width = label_width,
    show_edge_labels = show_edge_labels,
    show_tooltips = show_tooltips,
    same_rank = same_rank
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

  graph <- DiagrammeR::grViz(dot)
  if (identical(as, "diagrammer")) {
    return(graph)
  }
  if (!requireNamespace("DiagrammeRsvg", quietly = TRUE)) {
    stop(
      "`render_workflow_graphviz(..., as = \"svg\")` requires the `DiagrammeRsvg` package.",
      call. = FALSE
    )
  }
  DiagrammeRsvg::export_svg(graph)
}

#' Plot a workflow graph with DiagrammeR
#'
#' Creates a DiagrammeR graph from a workflow. This is preferred over base
#' `igraph` plotting for readable workflow DAG visualization.
#'
#' @param x A workflow specification or a [`Scaffolder`] instance.
#' @param rankdir Graphviz rank direction, for example `"TB"` or `"LR"`.
#' @param label_width Approximate wrapping width for node labels.
#' @param show_edge_labels Whether to show edge relation labels.
#' @param show_tooltips Whether to include Graphviz tooltip attributes. Defaults
#'   to `FALSE` because long prose tooltips can trigger Viz.js parse failures in
#'   some DiagrammeR renderers.
#' @param same_rank Optional list of node-id character vectors to keep at the
#'   same Graphviz rank.
#'
#' @return A `DiagrammeR` graph object.
#' @export
plot_workflow_graph <- function(
  x,
  rankdir = "TB",
  label_width = 28,
  show_edge_labels = FALSE,
  show_tooltips = FALSE,
  same_rank = NULL
) {
  render_workflow_graphviz(
    x = x,
    rankdir = rankdir,
    as = "diagrammer",
    label_width = label_width,
    show_edge_labels = show_edge_labels,
    show_tooltips = show_tooltips,
    same_rank = same_rank
  )
}
