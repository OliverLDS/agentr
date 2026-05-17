#' Create a knowledge-graph node record
#'
#' @param id Node identifier.
#' @param label Human-readable node label.
#' @param node_type Knowledge-graph node type.
#' @param memory_type Optional memory type: `context`, `semantic`, `episodic`,
#'   or `procedural`.
#' @param knowledge_form Knowledge form label. Defaults to `"graph"`.
#' @param item_type Optional knowledge-item type.
#' @param review_status Optional review status.
#' @param domain Optional domain label.
#' @param confidence Optional confidence label.
#' @param source_item_id Optional source knowledge-item id.
#' @param notes Optional node notes.
#' @param provenance Provenance metadata list.
#' @param review Review metadata list.
#' @param scope Scope metadata list.
#'
#' @return One-row data frame.
#' @export
knowledge_graph_node <- function(
  id,
  label,
  node_type = "knowledge_item",
  memory_type = NA_character_,
  knowledge_form = "graph",
  item_type = NA_character_,
  review_status = NA_character_,
  domain = NA_character_,
  confidence = NA_character_,
  source_item_id = NA_character_,
  notes = NA_character_,
  provenance = list(),
  review = list(status = "draft"),
  scope = list()
) {
  n <- length(id)
  if (!n) {
    out <- data.frame(
      id = character(),
      label = character(),
      node_type = character(),
      memory_type = character(),
      knowledge_form = character(),
      item_type = character(),
      review_status = character(),
      domain = character(),
      confidence = character(),
      source_item_id = character(),
      notes = character(),
      stringsAsFactors = FALSE
    )
    out$provenance <- I(list())
    out$review <- I(list())
    out$scope <- I(list())
    return(out)
  }

  out <- data.frame(
    id = as.character(id),
    label = as.character(label),
    node_type = as.character(node_type),
    memory_type = as.character(memory_type),
    knowledge_form = as.character(knowledge_form),
    item_type = as.character(item_type),
    review_status = as.character(review_status),
    domain = as.character(domain),
    confidence = as.character(confidence),
    source_item_id = as.character(source_item_id),
    notes = as.character(notes),
    stringsAsFactors = FALSE
  )
  out$provenance <- I(replicate(nrow(out), provenance, simplify = FALSE))
  out$review <- I(replicate(nrow(out), .normalize_knowledge_graph_review(review), simplify = FALSE))
  out$scope <- I(replicate(nrow(out), scope, simplify = FALSE))
  out
}

#' Create a knowledge-graph edge record
#'
#' @param from Source node id.
#' @param to Target node id.
#' @param relation Edge relation label.
#' @param relation_type Optional relation type label.
#' @param memory_type Optional memory type: `context`, `semantic`, `episodic`,
#'   or `procedural`.
#' @param confidence Optional edge confidence score between 0 and 1.
#' @param notes Optional edge notes.
#' @param provenance Provenance metadata list.
#' @param review Review metadata list.
#' @param scope Scope metadata list.
#'
#' @return One-row data frame.
#' @export
knowledge_graph_edge <- function(
  from,
  to,
  relation = "relates_to",
  relation_type = relation,
  memory_type = NA_character_,
  confidence = NA_real_,
  notes = NA_character_,
  provenance = list(),
  review = list(status = "draft"),
  scope = list()
) {
  n <- length(from)
  if (!n) {
    out <- data.frame(
      from = character(),
      to = character(),
      relation = character(),
      relation_type = character(),
      memory_type = character(),
      confidence = numeric(),
      notes = character(),
      stringsAsFactors = FALSE
    )
    out$provenance <- I(list())
    out$review <- I(list())
    out$scope <- I(list())
    return(out)
  }

  out <- data.frame(
    from = as.character(from),
    to = as.character(to),
    relation = as.character(relation),
    relation_type = as.character(relation_type),
    memory_type = as.character(memory_type),
    confidence = as.numeric(confidence),
    notes = as.character(notes),
    stringsAsFactors = FALSE
  )
  out$provenance <- I(replicate(nrow(out), provenance, simplify = FALSE))
  out$review <- I(replicate(nrow(out), .normalize_knowledge_graph_review(review), simplify = FALSE))
  out$scope <- I(replicate(nrow(out), scope, simplify = FALSE))
  out
}

#' @keywords internal
.empty_knowledge_graph_nodes <- function() {
  knowledge_graph_node(id = character(), label = character())
}

#' @keywords internal
.empty_knowledge_graph_edges <- function() {
  knowledge_graph_edge(from = character(), to = character())
}

#' @keywords internal
.normalize_knowledge_graph_review <- function(review) {
  if (is.null(review)) {
    review <- list(status = "draft")
  }
  if (!is.list(review)) {
    stop("Knowledge graph review metadata must be a list.", call. = FALSE)
  }
  if (is.null(review$status)) {
    review$status <- "draft"
  }
  review$status <- match.arg(as.character(review$status)[1], choices = .knowledge_review_statuses())
  review
}

#' @keywords internal
.normalize_knowledge_graph_nodes <- function(nodes) {
  if (!is.data.frame(nodes)) {
    stop("Knowledge graph `nodes` must be a data frame.", call. = FALSE)
  }
  if (!"memory_type" %in% names(nodes)) {
    nodes$memory_type <- NA_character_
  }
  if (!"knowledge_form" %in% names(nodes)) {
    nodes$knowledge_form <- "graph"
  }
  if (!"provenance" %in% names(nodes)) {
    nodes$provenance <- I(replicate(nrow(nodes), list(), simplify = FALSE))
  }
  if (!"review" %in% names(nodes)) {
    nodes$review <- I(replicate(nrow(nodes), list(status = "draft"), simplify = FALSE))
  }
  if (!"scope" %in% names(nodes)) {
    nodes$scope <- I(replicate(nrow(nodes), list(), simplify = FALSE))
  }
  nodes$memory_type <- as.character(nodes$memory_type)
  nodes$knowledge_form <- as.character(nodes$knowledge_form)
  nodes$review <- I(lapply(nodes$review, .normalize_knowledge_graph_review))
  nodes
}

#' @keywords internal
.normalize_knowledge_graph_edges <- function(edges) {
  if (!is.data.frame(edges)) {
    stop("Knowledge graph `edges` must be a data frame.", call. = FALSE)
  }
  if (!"relation_type" %in% names(edges)) {
    edges$relation_type <- edges$relation
  }
  if (!"memory_type" %in% names(edges)) {
    edges$memory_type <- NA_character_
  }
  if (!"provenance" %in% names(edges)) {
    edges$provenance <- I(replicate(nrow(edges), list(), simplify = FALSE))
  }
  if (!"review" %in% names(edges)) {
    edges$review <- I(replicate(nrow(edges), list(status = "draft"), simplify = FALSE))
  }
  if (!"scope" %in% names(edges)) {
    edges$scope <- I(replicate(nrow(edges), list(), simplify = FALSE))
  }
  edges$relation_type <- as.character(edges$relation_type)
  edges$memory_type <- as.character(edges$memory_type)
  edges$review <- I(lapply(edges$review, .normalize_knowledge_graph_review))
  edges
}

#' Create a knowledge-graph specification
#'
#' A knowledge-graph specification is a first-class graph-knowledge
#' representation. It can store curated nodes and typed relationships directly,
#' and it can also hold projection graphs derived from narrative `KnowledgeSpec`
#' items for review and visualization.
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
  nodes <- .normalize_knowledge_graph_nodes(nodes)
  edges <- .normalize_knowledge_graph_edges(edges)
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
    "domain", "confidence", "source_item_id", "notes",
    "memory_type", "knowledge_form", "provenance", "review", "scope"
  )
  required_edges <- c(
    "from", "to", "relation", "confidence", "notes",
    "relation_type", "memory_type", "provenance", "review", "scope"
  )

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
  node_memory <- x$nodes$memory_type[!is.na(x$nodes$memory_type) & nzchar(x$nodes$memory_type)]
  edge_memory <- x$edges$memory_type[!is.na(x$edges$memory_type) & nzchar(x$edges$memory_type)]
  invalid_memory <- setdiff(unique(c(node_memory, edge_memory)), memory_types())
  if (length(invalid_memory)) {
    stop("Knowledge graph memory types must be one of: ", paste(memory_types(), collapse = ", "), call. = FALSE)
  }
  if (any(!x$nodes$knowledge_form %in% c("graph", "projection", "hybrid"))) {
    stop("Knowledge graph node `knowledge_form` must be graph, projection, or hybrid.", call. = FALSE)
  }
  invisible(lapply(x$nodes$review, .normalize_knowledge_graph_review))
  invisible(lapply(x$edges$review, .normalize_knowledge_graph_review))

  invisible(x)
}

#' Add a node to a knowledge graph specification
#'
#' @param graph Knowledge graph specification.
#' @param ... Arguments passed to [knowledge_graph_node()].
#'
#' @return Updated `agentr_knowledge_graph_spec`.
#' @export
add_knowledge_graph_node <- function(graph, ...) {
  validate_knowledge_graph_spec(graph)
  node <- knowledge_graph_node(...)
  if (node$id[[1]] %in% graph$nodes$id) {
    stop("Duplicate knowledge graph node id: ", node$id[[1]], call. = FALSE)
  }
  new_knowledge_graph_spec(
    nodes = rbind(graph$nodes, node),
    edges = graph$edges,
    metadata = graph$metadata
  )
}

#' Add an edge to a knowledge graph specification
#'
#' @param graph Knowledge graph specification.
#' @param ... Arguments passed to [knowledge_graph_edge()].
#'
#' @return Updated `agentr_knowledge_graph_spec`.
#' @export
add_knowledge_graph_edge <- function(graph, ...) {
  validate_knowledge_graph_spec(graph)
  edge <- knowledge_graph_edge(...)
  refs <- c(edge$from[[1]], edge$to[[1]])
  missing <- setdiff(refs, graph$nodes$id)
  if (length(missing)) {
    stop("Knowledge graph edge references unknown node ids: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  new_knowledge_graph_spec(
    nodes = graph$nodes,
    edges = rbind(graph$edges, edge),
    metadata = graph$metadata
  )
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

#' Build a projection graph from narrative KnowledgeSpec items
#'
#' Converts approved or draft knowledge items into a graph-ready structure with
#' nodes for knowledge items, domains, conditions, exceptions, and
#' structure-derived concepts. This creates a projection graph from narrative
#' knowledge; curated graph knowledge can be authored directly with
#' `new_knowledge_graph_spec()`, `add_knowledge_graph_node()`, and
#' `add_knowledge_graph_edge()`.
#'
#' @param x A [`KnowledgeSpec`] object.
#' @param include_domains Whether to include domain nodes.
#' @param include_conditions Whether to include condition nodes.
#' @param include_exceptions Whether to include exception nodes.
#' @param include_structure Whether to include structure-derived concept nodes.
#' @param include_conflicts Whether to include conflict edges when present.
#'
#' @return An `agentr_knowledge_graph_spec`.
#'
#' @examples
#' ks <- KnowledgeSpec$new(items = list(list(
#'   id = "ki_yoy_macro_001",
#'   type = "heuristic",
#'   raw_statement = "Use YoY when monthly macro data is noisy.",
#'   normalized_statement = "Use YoY transformations for noisy monthly macro data.",
#'   domain = "macro_analysis",
#'   conditions = c("monthly macro data"),
#'   exceptions = c("short-term shock timing"),
#'   review = list(status = "approved")
#' )))
#'
#' kg <- knowledge_graph_from_spec(ks)
#' knowledge_graph_data(kg)
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
      memory_type = "semantic",
      knowledge_form = "projection",
      item_type = item$type,
      review_status = item$review$status,
      domain = item$domain,
      confidence = item$confidence,
      source_item_id = item$id,
      notes = item$raw_statement,
      provenance = item$provenance,
      review = item$review,
      scope = list(domain = item$domain)
    ))

    if (isTRUE(include_domains) && !is.na(item$domain) && nzchar(item$domain)) {
      domain_id <- paste0("domain::", item$domain)
      add_node(knowledge_graph_node(
        id = domain_id,
        label = item$domain,
        node_type = "domain",
        memory_type = "semantic",
        knowledge_form = "projection",
        domain = item$domain,
        source_item_id = item$id,
        scope = list(domain = item$domain)
      ))
      add_edge(knowledge_graph_edge(
        item$id,
        domain_id,
        relation = "in_domain",
        relation_type = "in_domain",
        memory_type = "semantic",
        provenance = item$provenance,
        review = item$review,
        scope = list(domain = item$domain)
      ))
    }

    if (isTRUE(include_conditions) && length(item$conditions)) {
      for (idx in seq_along(item$conditions)) {
        cond <- item$conditions[[idx]]
        cond_id <- paste0(item$id, "::condition::", idx)
        add_node(knowledge_graph_node(
          id = cond_id,
          label = cond,
          node_type = "condition",
          memory_type = "semantic",
          knowledge_form = "projection",
          source_item_id = item$id,
          provenance = item$provenance,
          review = item$review,
          scope = list(domain = item$domain)
        ))
        add_edge(knowledge_graph_edge(
          item$id,
          cond_id,
          relation = "condition",
          relation_type = "condition",
          memory_type = "semantic",
          provenance = item$provenance,
          review = item$review,
          scope = list(domain = item$domain)
        ))
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
          memory_type = "semantic",
          knowledge_form = "projection",
          source_item_id = item$id,
          provenance = item$provenance,
          review = item$review,
          scope = list(domain = item$domain)
        ))
        add_edge(knowledge_graph_edge(
          item$id,
          exc_id,
          relation = "exception",
          relation_type = "exception",
          memory_type = "semantic",
          provenance = item$provenance,
          review = item$review,
          scope = list(domain = item$domain)
        ))
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
          memory_type = "semantic",
          knowledge_form = "projection",
          source_item_id = item$id,
          provenance = item$provenance,
          review = item$review,
          scope = list(domain = item$domain)
        ))
        relation <- switch(
          name,
          cause = "has_cause",
          effect = "has_effect",
          direction = "has_direction",
          "has_structure"
        )
        add_edge(knowledge_graph_edge(
          item$id,
          concept_id,
          relation = relation,
          relation_type = relation,
          memory_type = "semantic",
          provenance = item$provenance,
          review = item$review,
          scope = list(domain = item$domain)
        ))
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
              memory_type = "semantic",
              knowledge_form = "projection",
              source_item_id = target
            ))
          }
          add_edge(knowledge_graph_edge(
            item$id,
            target,
            relation = if (is.null(conflict$conflict_type)) "conflict" else as.character(conflict$conflict_type)[1],
            relation_type = if (is.null(conflict$conflict_type)) "conflict" else as.character(conflict$conflict_type)[1],
            memory_type = "semantic",
            notes = if (is.null(conflict$explanation)) NA_character_ else as.character(conflict$explanation)[1],
            provenance = item$provenance,
            review = item$review,
            scope = list(domain = item$domain)
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
      graph_mode = "projection",
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
#' Returns styled vertex and edge tables suitable for external graph renderers
#' or the package's Graphviz rendering helpers.
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
    if (.dot_present(nodes$memory_type[[i]])) paste0("memory_type: ", nodes$memory_type[[i]]) else NULL,
    if (.dot_present(nodes$knowledge_form[[i]])) paste0("knowledge_form: ", nodes$knowledge_form[[i]]) else NULL,
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
#' This helper renders first-class graph knowledge or projection graphs derived
#' from narrative knowledge. It mirrors the workflow graph rendering path, but
#' the nodes and edges represent concepts, knowledge items, conditions,
#' exceptions, typed relations, and conflicts.
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
#'
#' @examples
#' ks <- KnowledgeSpec$new(items = list(list(
#'   id = "ki_yoy_macro_001",
#'   type = "heuristic",
#'   raw_statement = "Use YoY when monthly macro data is noisy.",
#'   normalized_statement = "Use YoY transformations for noisy monthly macro data.",
#'   domain = "macro_analysis",
#'   review = list(status = "approved")
#' )))
#'
#' dot <- render_knowledge_graphviz(ks, as = "dot")
#' cat(dot)
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
#' Returns an interactive DiagrammeR graph for human inspection of a
#' `KnowledgeSpec` or `agentr_knowledge_graph_spec`. Use
#' `render_knowledge_graphviz(..., as = "dot")` when a plain text artifact is
#' easier to inspect or test.
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
