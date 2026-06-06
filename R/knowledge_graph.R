#' @keywords internal
.empty_graph_nodes <- function() {
  data.frame(
    id = character(),
    label = character(),
    node_type = character(),
    memory_type = character(),
    source_id = character(),
    source_type = character(),
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.empty_graph_edges <- function() {
  data.frame(
    from = character(),
    to = character(),
    relation = character(),
    relation_type = character(),
    memory_type = character(),
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.graph_record_value <- function(record, name, default = NA_character_) {
  value <- record[[name]]
  if (is.null(value) || !length(value)) {
    return(default)
  }
  as.character(value)[1]
}

#' @keywords internal
.normalize_graph_nodes <- function(nodes) {
  if (is.null(nodes)) {
    return(.empty_graph_nodes())
  }
  if (is.data.frame(nodes)) {
    if (!nrow(nodes)) {
      return(.empty_graph_nodes())
    }
    records <- .design_df_records(nodes)
  } else if (is.list(nodes)) {
    records <- nodes
  } else {
    stop("Graph representation `nodes` must be a data frame or list.", call. = FALSE)
  }
  if (!length(records)) {
    return(.empty_graph_nodes())
  }
  out <- data.frame(
    id = vapply(records, .graph_record_value, character(1), name = "id"),
    label = vapply(records, .graph_record_value, character(1), name = "label"),
    node_type = vapply(records, .graph_record_value, character(1), name = "node_type", default = "concept"),
    memory_type = vapply(records, .graph_record_value, character(1), name = "memory_type"),
    source_id = vapply(records, .graph_record_value, character(1), name = "source_id"),
    source_type = vapply(records, .graph_record_value, character(1), name = "source_type"),
    stringsAsFactors = FALSE
  )
  out$metadata <- I(lapply(records, function(record) {
    metadata <- record$metadata
    if (is.null(metadata)) list() else metadata
  }))
  missing_label <- is.na(out$label) | !nzchar(out$label)
  out$label[missing_label] <- out$id[missing_label]
  out
}

#' @keywords internal
.normalize_graph_edges <- function(edges) {
  if (is.null(edges)) {
    return(.empty_graph_edges())
  }
  if (is.data.frame(edges)) {
    if (!nrow(edges)) {
      return(.empty_graph_edges())
    }
    records <- .design_df_records(edges)
  } else if (is.list(edges)) {
    records <- edges
  } else {
    stop("Graph representation `edges` must be a data frame or list.", call. = FALSE)
  }
  if (!length(records)) {
    return(.empty_graph_edges())
  }
  out <- data.frame(
    from = vapply(records, .graph_record_value, character(1), name = "from"),
    to = vapply(records, .graph_record_value, character(1), name = "to"),
    relation = vapply(records, .graph_record_value, character(1), name = "relation", default = "relates_to"),
    relation_type = vapply(records, .graph_record_value, character(1), name = "relation_type"),
    memory_type = vapply(records, .graph_record_value, character(1), name = "memory_type"),
    stringsAsFactors = FALSE
  )
  out$metadata <- I(lapply(records, function(record) {
    metadata <- record$metadata
    if (is.null(metadata)) list() else metadata
  }))
  missing_relation_type <- is.na(out$relation_type) | !nzchar(out$relation_type)
  out$relation_type[missing_relation_type] <- out$relation[missing_relation_type]
  out
}

#' @keywords internal
.graph_data_from_representation <- function(graph) {
  if (is.null(graph)) {
    return(list(nodes = .empty_graph_nodes(), edges = .empty_graph_edges(), metadata = list()))
  }
  if (!is.list(graph) || !all(c("nodes", "edges") %in% names(graph))) {
    stop("Graph representation must be a list with `nodes` and `edges`.", call. = FALSE)
  }
  nodes <- .normalize_graph_nodes(graph$nodes)
  edges <- .normalize_graph_edges(graph$edges)
  if (nrow(nodes) && any(!nzchar(nodes$id) | is.na(nodes$id))) {
    stop("Graph representation nodes require non-empty `id` values.", call. = FALSE)
  }
  if (anyDuplicated(nodes$id)) {
    stop("Graph representation node ids must be unique.", call. = FALSE)
  }
  if (nrow(edges)) {
    if (any(!nzchar(edges$from) | is.na(edges$from)) || any(!nzchar(edges$to) | is.na(edges$to))) {
      stop("Graph representation edges require non-empty `from` and `to` values.", call. = FALSE)
    }
    missing <- setdiff(unique(c(edges$from, edges$to)), nodes$id)
    if (length(missing)) {
      stop("Graph representation edges reference missing node ids: ", paste(missing, collapse = ", "), call. = FALSE)
    }
  }
  metadata <- graph$metadata
  if (is.null(metadata)) {
    metadata <- list()
  }
  .validate_metadata_list(metadata)
  list(nodes = nodes, edges = edges, metadata = metadata)
}

#' @keywords internal
.graph_representation_to_list <- function(graph) {
  graph <- .graph_data_from_representation(graph)
  list(
    nodes = .design_df_records(graph$nodes),
    edges = .design_df_records(graph$edges),
    metadata = graph$metadata
  )
}

#' @keywords internal
.coerce_graph_representation_or_null <- function(graph) {
  if (is.null(graph)) {
    return(NULL)
  }
  .graph_representation_to_list(graph)
}

#' @keywords internal
.knowledge_graph_from_knowledge_spec <- function(x) {
  x$validate()
  if (!is.null(x$graph)) {
    return(.graph_data_from_representation(x$graph))
  }
  nodes <- .empty_graph_nodes()
  edges <- .empty_graph_edges()
  node_records <- list()
  edge_records <- list()
  add_node <- function(id, label, node_type, source_id = NA_character_, source_type = NA_character_) {
    if (id %in% vapply(node_records, function(node) node$id, character(1))) {
      return(invisible(NULL))
    }
    node_records[[length(node_records) + 1L]] <<- list(
      id = id,
      label = label,
      node_type = node_type,
      source_id = source_id,
      source_type = source_type
    )
    invisible(NULL)
  }
  add_edge <- function(from, to, relation) {
    edge_records[[length(edge_records) + 1L]] <<- list(from = from, to = to, relation = relation)
    invisible(NULL)
  }
  for (item in x$list_items()) {
    add_node(
      item$id,
      if (!is.na(item$normalized_statement) && nzchar(item$normalized_statement)) item$normalized_statement else item$raw_statement,
      "knowledge_item",
      source_id = item$id,
      source_type = item$type
    )
    if (!is.na(item$domain) && nzchar(item$domain)) {
      domain_id <- paste0("domain::", item$domain)
      add_node(domain_id, item$domain, "domain")
      add_edge(item$id, domain_id, "domain")
    }
  }
  if (length(node_records)) {
    nodes <- .normalize_graph_nodes(node_records)
  }
  if (length(edge_records)) {
    edges <- .normalize_graph_edges(edge_records)
  }
  list(nodes = nodes, edges = edges, metadata = list(source = "knowledge_spec_projection"))
}

#' @keywords internal
.knowledge_graph_from_memory_spec <- function(x) {
  x$validate()
  if (!is.null(x$graph)) {
    return(.graph_data_from_representation(x$graph))
  }
  records <- lapply(x$list_fields(), function(field) {
    list(
      id = field$id,
      label = field$label,
      node_type = "memory_field",
      memory_type = field$memory_type,
      source_id = field$id,
      source_type = "memory_field"
    )
  })
  list(
    nodes = .normalize_graph_nodes(records),
    edges = .empty_graph_edges(),
    metadata = list(source = "memory_spec_projection")
  )
}

#' Build graph data from knowledge, memory, or a graph representation
#'
#' `agentr` treats graph structure as a representation shape rather than as a
#' separate first-class spec. This helper returns graph-ready node and edge data
#' from a [`KnowledgeSpec`], [`MemorySpec`], or plain `list(nodes, edges,
#' metadata)` graph representation.
#'
#' @param x A [`KnowledgeSpec`], [`MemorySpec`], or plain graph list with
#'   `nodes` and `edges`.
#'
#' @return A list with `nodes`, `edges`, and `metadata`.
#' @export
knowledge_graph_data <- function(x) {
  if (inherits(x, "KnowledgeSpec")) {
    return(.knowledge_graph_from_knowledge_spec(x))
  }
  if (inherits(x, "MemorySpec")) {
    return(.knowledge_graph_from_memory_spec(x))
  }
  .graph_data_from_representation(x)
}

#' Build a graph representation from a knowledge or memory spec
#'
#' This is a compatibility-oriented alias for [knowledge_graph_data()]. It no
#' longer returns a separate `KnowledgeGraphSpec`; graph is now a representation
#' shape embedded in knowledge or memory specs.
#'
#' @param x A [`KnowledgeSpec`], [`MemorySpec`], or graph representation list.
#'
#' @return A list with graph-ready `nodes`, `edges`, and `metadata`.
#' @export
knowledge_graph_from_spec <- function(x) {
  knowledge_graph_data(x)
}

#' @keywords internal
.knowledge_graph_node_tooltip <- function(nodes, i) {
  parts <- c(
    paste0("id: ", nodes$id[[i]]),
    paste0("type: ", nodes$node_type[[i]])
  )
  if (!is.na(nodes$memory_type[[i]]) && nzchar(nodes$memory_type[[i]])) {
    parts <- c(parts, paste0("memory_type: ", nodes$memory_type[[i]]))
  }
  .dot_escape_multiline(paste(parts, collapse = "\n"))
}

#' @keywords internal
.knowledge_graph_dot <- function(
  graph_data,
  rankdir = "TB",
  label_width = 28,
  show_edge_labels = TRUE,
  show_tooltips = FALSE
) {
  nodes <- graph_data$nodes
  edges <- graph_data$edges
  nodes$label_prepared <- vapply(nodes$label, .dot_prepare_label, character(1), width = label_width)
  node_lines <- if (nrow(nodes)) {
    vapply(seq_len(nrow(nodes)), function(i) {
      fill <- switch(
        nodes$node_type[[i]],
        domain = "#F3E8FF",
        memory_field = "#DCFCE7",
        knowledge_item = "#DBEAFE",
        "#F3F4F6"
      )
      stroke <- switch(
        nodes$node_type[[i]],
        domain = "#7E22CE",
        memory_field = "#15803D",
        knowledge_item = "#1D4ED8",
        "#6B7280"
      )
      tooltip <- if (isTRUE(show_tooltips)) {
        sprintf(', tooltip="%s"', .knowledge_graph_node_tooltip(nodes, i))
      } else {
        ""
      }
      paste0(
        sprintf(
          '  "%s" [label="%s", shape=box, style="rounded,filled", fillcolor="%s", color="%s", fontname="Helvetica", fontsize=11',
          .dot_escape_id(nodes$id[[i]]),
          nodes$label_prepared[[i]],
          fill,
          stroke
        ),
        tooltip,
        "];"
      )
    }, character(1))
  } else {
    character()
  }
  edge_lines <- if (nrow(edges)) {
    vapply(seq_len(nrow(edges)), function(i) {
      label <- if (isTRUE(show_edge_labels)) .dot_prepare_label(edges$relation[[i]], width = 100) else ""
      sprintf(
        '  "%s" -> "%s" [color="#6B7280", penwidth=1.2, arrowsize=0.8, label="%s", fontname="Helvetica", fontsize=9];',
        .dot_escape_id(edges$from[[i]]),
        .dot_escape_id(edges$to[[i]]),
        label
      )
    }, character(1))
  } else {
    character()
  }
  paste(
    "digraph knowledge {",
    sprintf('  graph [layout=dot, rankdir=%s, nodesep=0.45, ranksep=0.70, splines=spline, pad=0.2];', rankdir),
    '  node [fontname="Helvetica"];',
    '  edge [fontname="Helvetica"];',
    paste(node_lines, collapse = "\n"),
    paste(edge_lines, collapse = "\n"),
    "}",
    sep = "\n"
  )
}

#' Render a graph representation as Graphviz DOT, DiagrammeR, or SVG
#'
#' This helper renders graph-shaped knowledge or memory. It accepts a
#' [`KnowledgeSpec`], [`MemorySpec`], or plain `list(nodes, edges, metadata)`
#' graph representation. It does not require or create a separate graph spec.
#'
#' @param x A [`KnowledgeSpec`], [`MemorySpec`], or graph representation list.
#' @param rankdir Graphviz rank direction, for example `"TB"` or `"LR"`.
#' @param as Output format: raw `"dot"` text, a `"diagrammer"` object, or
#'   exported `"svg"` text.
#' @param label_width Approximate wrapping width for node labels.
#' @param show_edge_labels Whether to show edge relation labels.
#' @param show_tooltips Whether to include Graphviz tooltip attributes.
#'
#' @return A Graphviz DOT string, `DiagrammeR` graph object, or SVG string.
#' @export
render_knowledge_graphviz <- function(
  x,
  rankdir = "TB",
  as = c("dot", "diagrammer", "svg"),
  label_width = 28,
  show_edge_labels = TRUE,
  show_tooltips = FALSE
) {
  as <- match.arg(as)
  graph_data <- knowledge_graph_data(x)
  dot <- .knowledge_graph_dot(
    graph_data = graph_data,
    rankdir = rankdir,
    label_width = label_width,
    show_edge_labels = show_edge_labels,
    show_tooltips = show_tooltips
  )
  if (identical(as, "dot")) {
    return(dot)
  }
  if (!requireNamespace("DiagrammeR", quietly = TRUE)) {
    stop(
      "`render_knowledge_graphviz(..., as = \"diagrammer\")` requires the `DiagrammeR` package.",
      call. = FALSE
    )
  }
  graph <- DiagrammeR::grViz(dot)
  if (identical(as, "diagrammer")) {
    return(graph)
  }
  if (!requireNamespace("DiagrammeRsvg", quietly = TRUE)) {
    stop(
      "`render_knowledge_graphviz(..., as = \"svg\")` requires the `DiagrammeRsvg` package.",
      call. = FALSE
    )
  }
  DiagrammeRsvg::export_svg(graph)
}

#' Plot a graph-shaped knowledge or memory representation
#'
#' @param x A [`KnowledgeSpec`], [`MemorySpec`], or graph representation list.
#' @param rankdir Graphviz rank direction, for example `"TB"` or `"LR"`.
#' @param label_width Approximate wrapping width for node labels.
#' @param show_edge_labels Whether to show edge relation labels.
#' @param show_tooltips Whether to include Graphviz tooltip attributes.
#'
#' @return A `DiagrammeR` graph object.
#' @export
plot_knowledge_graph <- function(
  x,
  rankdir = "TB",
  label_width = 28,
  show_edge_labels = TRUE,
  show_tooltips = FALSE
) {
  render_knowledge_graphviz(
    x = x,
    rankdir = rankdir,
    as = "diagrammer",
    label_width = label_width,
    show_edge_labels = show_edge_labels,
    show_tooltips = show_tooltips
  )
}
