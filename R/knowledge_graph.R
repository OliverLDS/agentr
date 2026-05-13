#' Create a knowledge-graph node record
#'
#' @param id Node identifier.
#' @param label Human-readable node label.
#' @param node_type Knowledge-graph node type.
#' @param item_type Optional knowledge-item type.
#' @param review_status Optional review status.
#' @param domain Optional domain label.
#' @param confidence Optional confidence label.
#' @param source_item_id Optional source knowledge-item id.
#' @param notes Optional node notes.
#'
#' @return One-row data frame.
#' @export
knowledge_graph_node <- function(
  id,
  label,
  node_type = "knowledge_item",
  item_type = NA_character_,
  review_status = NA_character_,
  domain = NA_character_,
  confidence = NA_character_,
  source_item_id = NA_character_,
  notes = NA_character_
) {
  data.frame(
    id = as.character(id),
    label = as.character(label),
    node_type = as.character(node_type),
    item_type = as.character(item_type),
    review_status = as.character(review_status),
    domain = as.character(domain),
    confidence = as.character(confidence),
    source_item_id = as.character(source_item_id),
    notes = as.character(notes),
    stringsAsFactors = FALSE
  )
}

#' Create a knowledge-graph edge record
#'
#' @param from Source node id.
#' @param to Target node id.
#' @param relation Edge relation label.
#' @param confidence Optional edge confidence score between 0 and 1.
#' @param notes Optional edge notes.
#'
#' @return One-row data frame.
#' @export
knowledge_graph_edge <- function(
  from,
  to,
  relation = "relates_to",
  confidence = NA_real_,
  notes = NA_character_
) {
  data.frame(
    from = as.character(from),
    to = as.character(to),
    relation = as.character(relation),
    confidence = as.numeric(confidence),
    notes = as.character(notes),
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.empty_knowledge_graph_nodes <- function() {
  knowledge_graph_node(
    id = character(),
    label = character(),
    node_type = character(),
    item_type = character(),
    review_status = character(),
    domain = character(),
    confidence = character(),
    source_item_id = character(),
    notes = character()
  )
}

#' @keywords internal
.empty_knowledge_graph_edges <- function() {
  knowledge_graph_edge(
    from = character(),
    to = character(),
    relation = character(),
    confidence = numeric(),
    notes = character()
  )
}

#' Create a knowledge-graph specification
#'
#' @param nodes Data frame of graph nodes.
#' @param edges Data frame of graph edges.
#' @param metadata Additional metadata list.
#'
#' @return An object of class `agentr_knowledge_graph_spec`.
#' @export
new_knowledge_graph_spec <- function(
  nodes = .empty_knowledge_graph_nodes(),
  edges = .empty_knowledge_graph_edges(),
  metadata = list()
) {
  spec <- list(
    nodes = nodes,
    edges = edges,
    metadata = metadata
  )
  class(spec) <- c("agentr_knowledge_graph_spec", class(spec))
  validate_knowledge_graph_spec(spec)
}

#' Validate a knowledge-graph specification
#'
#' @param x Knowledge-graph specification.
#'
#' @return The validated object, invisibly.
#' @export
validate_knowledge_graph_spec <- function(x) {
  required_nodes <- c(
    "id", "label", "node_type", "item_type", "review_status",
    "domain", "confidence", "source_item_id", "notes"
  )
  required_edges <- c("from", "to", "relation", "confidence", "notes")

  if (!is.list(x) || !all(c("nodes", "edges", "metadata") %in% names(x))) {
    stop("Knowledge graph spec must contain nodes, edges, and metadata.", call. = FALSE)
  }
  if (!is.data.frame(x$nodes)) {
    stop("Knowledge graph `nodes` must be a data frame.", call. = FALSE)
  }
  if (!is.data.frame(x$edges)) {
    stop("Knowledge graph `edges` must be a data frame.", call. = FALSE)
  }
  if (!all(required_nodes %in% names(x$nodes))) {
    stop("Knowledge graph nodes are missing required columns.", call. = FALSE)
  }
  if (!all(required_edges %in% names(x$edges))) {
    stop("Knowledge graph edges are missing required columns.", call. = FALSE)
  }
  if (anyDuplicated(x$nodes$id)) {
    stop("Knowledge graph node ids must be unique.", call. = FALSE)
  }
  if (!is.list(x$metadata)) {
    stop("Knowledge graph metadata must be a list.", call. = FALSE)
  }

  edge_refs <- unique(c(x$edges$from, x$edges$to))
  edge_refs <- edge_refs[nzchar(edge_refs)]
  if (length(edge_refs) && any(!(edge_refs %in% x$nodes$id))) {
    stop("Knowledge graph edges must reference existing node ids.", call. = FALSE)
  }

  numeric_fields <- x$edges$confidence
  numeric_fields <- numeric_fields[!is.na(numeric_fields)]
  if (length(numeric_fields) && any(numeric_fields < 0 | numeric_fields > 1)) {
    stop("Knowledge graph edge confidence values must be in [0, 1].", call. = FALSE)
  }

  invisible(x)
}

#' Format a knowledge-graph specification
#'
#' @param x Knowledge-graph specification.
#' @param ... Unused.
#'
#' @export
print.agentr_knowledge_graph_spec <- function(x, ...) {
  cat("<agentr_knowledge_graph_spec>\n")
  cat("Nodes:", nrow(x$nodes), "\n")
  cat("Edges:", nrow(x$edges), "\n")
  invisible(x)
}

#' Build a knowledge-graph specification from a KnowledgeSpec
#'
#' @param x A [`KnowledgeSpec`] object.
#' @param include_domains Whether to include domain nodes.
#' @param include_conditions Whether to include condition nodes.
#' @param include_exceptions Whether to include exception nodes.
#' @param include_structure Whether to include structure-derived concept nodes.
#' @param include_conflicts Whether to include conflict edges when present.
#'
#' @return An `agentr_knowledge_graph_spec`.
#' @export
knowledge_graph_from_spec <- function(
  x,
  include_domains = TRUE,
  include_conditions = TRUE,
  include_exceptions = TRUE,
  include_structure = TRUE,
  include_conflicts = TRUE
) {
  validate_knowledge_spec(x)
  items <- x$list_items()
  nodes <- .empty_knowledge_graph_nodes()
  edges <- .empty_knowledge_graph_edges()

  add_node <- function(node) {
    if (node$id[[1]] %in% nodes$id) {
      return(invisible(NULL))
    }
    nodes <<- rbind(nodes, node)
    invisible(NULL)
  }
  add_edge <- function(edge) {
    edges <<- rbind(edges, edge)
    invisible(NULL)
  }

  for (item in items) {
    item_label <- item$normalized_statement
    if (is.na(item_label) || !nzchar(item_label)) {
      item_label <- item$raw_statement
    }
    add_node(knowledge_graph_node(
      id = item$id,
      label = item_label,
      node_type = "knowledge_item",
      item_type = item$type,
      review_status = item$review$status,
      domain = item$domain,
      confidence = item$confidence,
      source_item_id = item$id,
      notes = item$raw_statement
    ))

    if (isTRUE(include_domains) && !is.na(item$domain) && nzchar(item$domain)) {
      domain_id <- paste0("domain::", item$domain)
      add_node(knowledge_graph_node(
        id = domain_id,
        label = item$domain,
        node_type = "domain",
        domain = item$domain
      ))
      add_edge(knowledge_graph_edge(item$id, domain_id, relation = "in_domain"))
    }

    if (isTRUE(include_conditions) && length(item$conditions)) {
      for (idx in seq_along(item$conditions)) {
        cond <- item$conditions[[idx]]
        cond_id <- paste0(item$id, "::condition::", idx)
        add_node(knowledge_graph_node(
          id = cond_id,
          label = cond,
          node_type = "condition",
          source_item_id = item$id
        ))
        add_edge(knowledge_graph_edge(item$id, cond_id, relation = "condition"))
      }
    }

    if (isTRUE(include_exceptions) && length(item$exceptions)) {
      for (idx in seq_along(item$exceptions)) {
        exc <- item$exceptions[[idx]]
        exc_id <- paste0(item$id, "::exception::", idx)
        add_node(knowledge_graph_node(
          id = exc_id,
          label = exc,
          node_type = "exception",
          source_item_id = item$id
        ))
        add_edge(knowledge_graph_edge(item$id, exc_id, relation = "exception"))
      }
    }

    if (isTRUE(include_structure) && length(item$structure)) {
      for (name in names(item$structure)) {
        value <- item$structure[[name]]
        if (is.null(value) || length(value) != 1L || is.na(value) || !nzchar(as.character(value))) {
          next
        }
        concept_label <- as.character(value)
        concept_id <- paste0("concept::", concept_label)
        add_node(knowledge_graph_node(
          id = concept_id,
          label = concept_label,
          node_type = "concept",
          source_item_id = item$id
        ))
        relation <- switch(
          name,
          cause = "has_cause",
          effect = "has_effect",
          direction = "has_direction",
          "has_structure"
        )
        add_edge(knowledge_graph_edge(item$id, concept_id, relation = relation))
      }
    }

    if (isTRUE(include_conflicts) && length(item$conflicts)) {
      for (conflict in item$conflicts) {
        if (is.null(conflict$conflicting_item_ids)) {
          next
        }
        targets <- as.character(unlist(conflict$conflicting_item_ids, use.names = FALSE))
        targets <- targets[nzchar(targets)]
        for (target in targets) {
          if (!(target %in% nodes$id)) {
            add_node(knowledge_graph_node(
              id = target,
              label = target,
              node_type = "knowledge_item",
              source_item_id = target
            ))
          }
          add_edge(knowledge_graph_edge(
            item$id,
            target,
            relation = if (is.null(conflict$conflict_type)) "conflict" else as.character(conflict$conflict_type)[1],
            notes = if (is.null(conflict$explanation)) NA_character_ else as.character(conflict$explanation)[1]
          ))
        }
      }
    }
  }

  if (nrow(edges)) {
    edges <- edges[!duplicated(edges[, c("from", "to", "relation")]), , drop = FALSE]
  }

  new_knowledge_graph_spec(
    nodes = nodes,
    edges = edges,
    metadata = list(
      source = "knowledge_spec",
      item_count = length(items),
      include_domains = include_domains,
      include_conditions = include_conditions,
      include_exceptions = include_exceptions,
      include_structure = include_structure,
      include_conflicts = include_conflicts
    )
  )
}

#' Convert a knowledge-graph specification into graph-ready data
#'
#' @param x A knowledge-graph specification or a [`KnowledgeSpec`] object.
#'
#' @return A list with `vertices` and `edges` data frames.
#' @export
knowledge_graph_data <- function(x) {
  if (inherits(x, "KnowledgeSpec")) {
    x <- knowledge_graph_from_spec(x)
  }
  validate_knowledge_graph_spec(x)

  vertices <- x$nodes
  edges <- x$edges

  palette <- list(
    knowledge_item = list(fill = "#DBEAFE", border = "#1D4ED8", shape = "box"),
    domain = list(fill = "#EDE9FE", border = "#6D28D9", shape = "ellipse"),
    concept = list(fill = "#DCFCE7", border = "#15803D", shape = "ellipse"),
    condition = list(fill = "#FEF3C7", border = "#B45309", shape = "note"),
    exception = list(fill = "#FCE7F3", border = "#BE185D", shape = "note")
  )

  vertices$node_label <- vertices$label
  vertices$node_shape <- vapply(vertices$node_type, function(type) {
    if (is.null(palette[[type]])) {
      return("box")
    }
    palette[[type]]$shape
  }, character(1))
  vertices$node_color <- vapply(vertices$node_type, function(type) {
    if (is.null(palette[[type]])) {
      return("#DBEAFE")
    }
    palette[[type]]$fill
  }, character(1))
  vertices$node_border <- vapply(vertices$node_type, function(type) {
    if (is.null(palette[[type]])) {
      return("#1D4ED8")
    }
    palette[[type]]$border
  }, character(1))
  vertices$low_confidence <- vertices$confidence %in% "low"

  edges$edge_label <- edges$relation
  list(vertices = vertices, edges = edges)
}

#' @keywords internal
.knowledge_graph_node_tooltip <- function(nodes, i) {
  parts <- c(
    paste0("id: ", nodes$id[[i]]),
    if (.dot_present(nodes$node_type[[i]])) paste0("node_type: ", nodes$node_type[[i]]) else NULL,
    if (.dot_present(nodes$item_type[[i]])) paste0("item_type: ", nodes$item_type[[i]]) else NULL,
    if (.dot_present(nodes$review_status[[i]])) paste0("review_status: ", nodes$review_status[[i]]) else NULL,
    if (.dot_present(nodes$domain[[i]])) paste0("domain: ", nodes$domain[[i]]) else NULL,
    if (.dot_present(nodes$confidence[[i]])) paste0("confidence: ", nodes$confidence[[i]]) else NULL,
    if (.dot_present(nodes$notes[[i]])) paste0("notes: ", nodes$notes[[i]]) else NULL
  )
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
  nodes <- graph_data$vertices
  edges <- graph_data$edges
  node_labels <- nodes$node_label
  if (is.null(node_labels)) {
    node_labels <- nodes$label
  }
  nodes$label_prepared <- vapply(node_labels, .dot_prepare_label, character(1), width = label_width)

  node_lines <- vapply(seq_len(nrow(nodes)), function(i) {
    tooltip_part <- if (isTRUE(show_tooltips)) {
      sprintf(', tooltip="%s"', .knowledge_graph_node_tooltip(nodes, i))
    } else {
      ""
    }
    paste0(
      sprintf(
        paste0(
          '  "%s" [',
          'label="%s", shape=%s, style="%s", fillcolor="%s", color="%s", ',
          'fontcolor="#111827", fontname="Helvetica", fontsize=11, margin="0.18,0.10", penwidth=1.3'
        ),
        .dot_escape_id(nodes$id[[i]]),
        nodes$label_prepared[[i]],
        nodes$node_shape[[i]],
        "rounded,filled",
        nodes$node_color[[i]],
        nodes$node_border[[i]]
      ),
      tooltip_part,
      "];"
    )
  }, character(1))

  edge_lines <- if (nrow(edges)) {
    vapply(seq_len(nrow(edges)), function(i) {
      label <- if (isTRUE(show_edge_labels)) .dot_prepare_label(edges$relation[[i]], width = 100) else ""
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
          if (edges$relation[[i]] %in% c("conflict", "contradiction")) "#BE185D" else "#6B7280",
          if (edges$relation[[i]] %in% c("exception", "condition")) "dashed" else "solid",
          if (is.na(edges$confidence[[i]])) 1.2 else pmax(1.0, 1 + 2 * (edges$confidence[[i]] - 0.85)),
          label
        ),
        tooltip_part,
        "];"
      )
    }, character(1))
  } else {
    character()
  }

  paste(
    "digraph knowledge {",
    sprintf('  graph [layout=dot, rankdir=%s, nodesep=0.40, ranksep=0.65, splines=spline, pad=0.2];', rankdir),
    '  node [fontname="Helvetica"];',
    '  edge [fontname="Helvetica"];',
    paste(node_lines, collapse = "\n"),
    paste(edge_lines, collapse = "\n"),
    "}",
    sep = "\n"
  )
}

#' Render a knowledge graph as Graphviz DOT, DiagrammeR, or SVG
#'
#' @param x A knowledge-graph specification or a [`KnowledgeSpec`] object.
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

#' Plot a knowledge graph with DiagrammeR
#'
#' @param x A knowledge-graph specification or a [`KnowledgeSpec`] object.
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
