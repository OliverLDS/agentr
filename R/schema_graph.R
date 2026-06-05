#' @keywords internal
.schema_graph_empty_vertices <- function() {
  data.frame(
    id = character(),
    label = character(),
    node_type = character(),
    path = character(),
    value = character(),
    node_label = character(),
    node_shape = character(),
    node_color = character(),
    node_border = character(),
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.schema_graph_empty_edges <- function() {
  data.frame(
    from = character(),
    to = character(),
    relation = character(),
    edge_label = character(),
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.schema_graph_node_kind <- function(x) {
  if (is.null(x)) {
    return("null")
  }
  if (is.data.frame(x)) {
    return("table")
  }
  if (is.list(x)) {
    names_x <- names(x)
    if (length(x) && !is.null(names_x) && all(nzchar(names_x))) {
      return("object")
    }
    return("array")
  }
  if (is.character(x)) {
    return("string")
  }
  if (is.logical(x)) {
    return("boolean")
  }
  if (is.integer(x)) {
    return("integer")
  }
  if (is.numeric(x)) {
    return("number")
  }
  "scalar"
}

#' @keywords internal
.schema_graph_short_value <- function(x, max_items = 3L) {
  if (is.null(x) || is.list(x) || is.data.frame(x)) {
    return("")
  }
  values <- as.character(x)
  values <- values[!is.na(values)]
  if (!length(values)) {
    return("")
  }
  if (length(values) > max_items) {
    values <- c(values[seq_len(max_items)], "...")
  }
  paste(values, collapse = ", ")
}

#' @keywords internal
.schema_graph_style <- function(node_type) {
  palette <- list(
    schema = list(shape = "box", fill = "#F3F4F6", border = "#374151"),
    object = list(shape = "box", fill = "#DBEAFE", border = "#1D4ED8"),
    array = list(shape = "folder", fill = "#EDE9FE", border = "#6D28D9"),
    table = list(shape = "component", fill = "#DCFCE7", border = "#15803D"),
    string = list(shape = "note", fill = "#ECFDF5", border = "#047857"),
    boolean = list(shape = "note", fill = "#FEF3C7", border = "#B45309"),
    integer = list(shape = "note", fill = "#EFF6FF", border = "#2563EB"),
    number = list(shape = "note", fill = "#EFF6FF", border = "#2563EB"),
    scalar = list(shape = "note", fill = "#F3F4F6", border = "#6B7280"),
    null = list(shape = "note", fill = "#F9FAFB", border = "#9CA3AF")
  )
  if (is.null(palette[[node_type]])) {
    palette[[node_type]] <- palette$scalar
  }
  palette[[node_type]]
}

#' @keywords internal
.schema_graph_safe_id_part <- function(x) {
  x <- as.character(x)[1]
  if (is.na(x) || !nzchar(x)) {
    x <- "item"
  }
  x <- gsub("[^A-Za-z0-9_]+", "_", x)
  gsub("^_+|_+$", "", x)
}

#' @keywords internal
.schema_graph_node_record <- function(id, label, node_type, path, value = "") {
  style <- .schema_graph_style(node_type)
  display_label <- label
  if (nzchar(value)) {
    display_label <- paste0(label, "\n", value)
  }
  data.frame(
    id = as.character(id),
    label = as.character(label),
    node_type = as.character(node_type),
    path = as.character(path),
    value = as.character(value),
    node_label = as.character(display_label),
    node_shape = style$shape,
    node_color = style$fill,
    node_border = style$border,
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.schema_graph_edge_record <- function(from, to, relation) {
  data.frame(
    from = as.character(from),
    to = as.character(to),
    relation = as.character(relation),
    edge_label = as.character(relation),
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.schema_shape_walk <- function(x, id, label, path) {
  node_type <- .schema_graph_node_kind(x)
  root_type <- if (identical(path, "$")) "schema" else node_type
  vertices <- .schema_graph_node_record(
    id = id,
    label = label,
    node_type = root_type,
    path = path,
    value = .schema_graph_short_value(x)
  )
  edges <- .schema_graph_empty_edges()

  if (is.data.frame(x)) {
    x <- lapply(x, function(col) {
      list(type = .schema_graph_node_kind(col), example = .schema_graph_short_value(col))
    })
  }

  if (is.list(x) && length(x)) {
    names_x <- names(x)
    has_names <- !is.null(names_x) && all(nzchar(names_x))
    for (i in seq_along(x)) {
      child_name <- if (has_names) names_x[[i]] else paste0("[", i, "]")
      child_id <- paste0(id, "::", .schema_graph_safe_id_part(child_name), "_", i)
      child_label <- child_name
      child_path <- if (has_names) {
        paste0(path, ".", child_name)
      } else {
        paste0(path, "[", i, "]")
      }
      child <- .schema_shape_walk(x[[i]], child_id, child_label, child_path)
      vertices <- rbind(vertices, child$vertices)
      edges <- rbind(
        edges,
        .schema_graph_edge_record(
          from = id,
          to = child_id,
          relation = if (has_names) "field" else "item"
        ),
        child$edges
      )
    }
  }

  list(vertices = vertices, edges = edges)
}

#' Convert a schema shape into graph-ready data
#'
#' Converts a nested R list, JSON-schema-like object, vector, or data frame into
#' node and edge data frames. The output is a structural preview of the schema
#' shape, not a validator.
#'
#' @param x Schema object to inspect. Common inputs are workflow-node
#'   `input_schema` or `output_schema` lists.
#' @param root_id Root node identifier.
#' @param root_label Human-readable root node label.
#'
#' @return A list with `vertices` and `edges` data frames.
#' @export
schema_shape_graph_data <- function(
  x,
  root_id = "schema",
  root_label = "schema"
) {
  if (is.null(root_id) || !nzchar(as.character(root_id)[1])) {
    stop("`root_id` must be a non-empty string.", call. = FALSE)
  }
  if (is.null(root_label) || !nzchar(as.character(root_label)[1])) {
    stop("`root_label` must be a non-empty string.", call. = FALSE)
  }
  .schema_shape_walk(
    x = x,
    id = as.character(root_id)[1],
    label = as.character(root_label)[1],
    path = "$"
  )
}

#' @keywords internal
.memory_graph_style <- function(memory_type) {
  palette <- list(
    context = list(fill = "#DBEAFE", border = "#1D4ED8"),
    semantic = list(fill = "#DCFCE7", border = "#15803D"),
    episodic = list(fill = "#FEF3C7", border = "#B45309"),
    procedural = list(fill = "#FCE7F3", border = "#BE185D")
  )
  if (is.null(palette[[memory_type]])) {
    return(list(fill = "#F3F4F6", border = "#6B7280"))
  }
  palette[[memory_type]]
}

#' Convert a MemorySpec into graph-ready data
#'
#' Converts memory fields and their optional schema shapes into graph-ready node
#' and edge data. This is a design-review projection of memory structure, not a
#' runtime memory store.
#'
#' @param x A [`MemorySpec`] object.
#' @param include_field_schemas Whether to include nested schema-shape nodes for
#'   each memory field's `schema`.
#'
#' @return A list with `vertices` and `edges` data frames.
#' @export
memory_schema_graph_data <- function(x, include_field_schemas = TRUE) {
  validate_memory_spec(x)

  vertices <- .schema_graph_node_record(
    id = "memory_schema",
    label = "Memory schema",
    node_type = "schema",
    path = "$",
    value = ""
  )
  vertices$memory_type <- NA_character_
  vertices$persistence <- NA_character_
  vertices$description <- NA_character_
  edges <- .schema_graph_empty_edges()

  fields <- x$list_fields()
  if (!length(fields)) {
    return(list(vertices = vertices, edges = edges))
  }

  for (field in fields) {
    node_id <- paste0("field::", field$id)
    style <- .memory_graph_style(field$memory_type)
    node_label <- paste0(field$label, "\n", field$memory_type, " | ", field$persistence)
    field_node <- data.frame(
      id = node_id,
      label = field$label,
      node_type = "memory_field",
      path = paste0("$.fields.", field$id),
      value = "",
      node_label = node_label,
      node_shape = "box",
      node_color = style$fill,
      node_border = style$border,
      memory_type = field$memory_type,
      persistence = field$persistence,
      description = field$description,
      stringsAsFactors = FALSE
    )
    vertices <- rbind(vertices, field_node)
    edges <- rbind(edges, .schema_graph_edge_record("memory_schema", node_id, "has_field"))

    if (isTRUE(include_field_schemas) && length(field$schema)) {
      schema_id <- paste0("schema::", .schema_graph_safe_id_part(field$id))
      schema_graph <- schema_shape_graph_data(
        field$schema,
        root_id = schema_id,
        root_label = "schema"
      )
      schema_graph$vertices$memory_type <- field$memory_type
      schema_graph$vertices$persistence <- field$persistence
      schema_graph$vertices$description <- NA_character_
      vertices <- rbind(vertices, schema_graph$vertices)
      edges <- rbind(
        edges,
        .schema_graph_edge_record(node_id, schema_id, "has_schema"),
        schema_graph$edges
      )
    }
  }

  list(vertices = vertices, edges = edges)
}

#' @keywords internal
.schema_graph_node_tooltip <- function(nodes, i) {
  parts <- c(
    paste0("id: ", nodes$id[[i]]),
    if ("node_type" %in% names(nodes) && .dot_present(nodes$node_type[[i]])) paste0("node_type: ", nodes$node_type[[i]]) else NULL,
    if ("path" %in% names(nodes) && .dot_present(nodes$path[[i]])) paste0("path: ", nodes$path[[i]]) else NULL,
    if ("memory_type" %in% names(nodes) && .dot_present(nodes$memory_type[[i]])) paste0("memory_type: ", nodes$memory_type[[i]]) else NULL,
    if ("persistence" %in% names(nodes) && .dot_present(nodes$persistence[[i]])) paste0("persistence: ", nodes$persistence[[i]]) else NULL,
    if ("description" %in% names(nodes) && .dot_present(nodes$description[[i]])) paste0("description: ", nodes$description[[i]]) else NULL,
    if ("value" %in% names(nodes) && .dot_present(nodes$value[[i]])) paste0("value: ", nodes$value[[i]]) else NULL
  )
  .dot_escape_multiline(paste(parts, collapse = "\n"))
}

#' @keywords internal
.schema_graph_dot <- function(
  graph_data,
  graph_name = "schema_shape",
  rankdir = "TB",
  label_width = 28,
  show_edge_labels = TRUE,
  show_tooltips = FALSE
) {
  nodes <- graph_data$vertices
  edges <- graph_data$edges

  if (!"node_label" %in% names(nodes)) {
    nodes$node_label <- nodes$label
  }
  if (!"node_shape" %in% names(nodes)) {
    nodes$node_shape <- "box"
  }
  if (!"node_color" %in% names(nodes)) {
    nodes$node_color <- "#F3F4F6"
  }
  if (!"node_border" %in% names(nodes)) {
    nodes$node_border <- "#6B7280"
  }
  if (!"relation" %in% names(edges)) {
    edges$relation <- ""
  }

  node_lines <- vapply(seq_len(nrow(nodes)), function(i) {
    tooltip_part <- if (isTRUE(show_tooltips)) {
      sprintf(', tooltip="%s"', .schema_graph_node_tooltip(nodes, i))
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
        .dot_prepare_label(nodes$node_label[[i]], width = label_width),
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
      paste0(
        sprintf(
          paste0(
            '  "%s" -> "%s" [',
            'color="#6B7280", style="solid", penwidth=1.2, arrowsize=0.8, ',
            'label="%s", fontname="Helvetica", fontsize=9];'
          ),
          .dot_escape_id(edges$from[[i]]),
          .dot_escape_id(edges$to[[i]]),
          label
        )
      )
    }, character(1))
  } else {
    character()
  }

  paste(
    paste0("digraph ", graph_name, " {"),
    sprintf('  graph [layout=dot, rankdir=%s, nodesep=0.40, ranksep=0.65, splines=spline, pad=0.2];', rankdir),
    '  node [fontname="Helvetica"];',
    '  edge [fontname="Helvetica"];',
    paste(node_lines, collapse = "\n"),
    paste(edge_lines, collapse = "\n"),
    "}",
    sep = "\n"
  )
}

#' Render a schema shape as Graphviz DOT, DiagrammeR, or SVG
#'
#' Renders a structural preview of a nested schema object, such as a workflow
#' node's `input_schema` or `output_schema`.
#'
#' @param x Schema object to inspect.
#' @param root_id Root node identifier.
#' @param root_label Human-readable root node label.
#' @param rankdir Graphviz rank direction, for example `"TB"` or `"LR"`.
#' @param as Output format: raw `"dot"` text, a `"diagrammer"` object, or
#'   exported `"svg"` text.
#' @param label_width Approximate wrapping width for node labels.
#' @param show_edge_labels Whether to show edge relation labels.
#' @param show_tooltips Whether to include Graphviz tooltip attributes.
#'
#' @return A Graphviz DOT string, `DiagrammeR` graph object, or SVG string.
#' @export
render_schema_shape_graphviz <- function(
  x,
  root_id = "schema",
  root_label = "schema",
  rankdir = "TB",
  as = c("dot", "diagrammer", "svg"),
  label_width = 28,
  show_edge_labels = TRUE,
  show_tooltips = FALSE
) {
  as <- match.arg(as)
  graph_data <- schema_shape_graph_data(x, root_id = root_id, root_label = root_label)
  dot <- .schema_graph_dot(
    graph_data = graph_data,
    graph_name = "schema_shape",
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
      "`render_schema_shape_graphviz(..., as = \"diagrammer\")` requires the `DiagrammeR` package.",
      call. = FALSE
    )
  }
  graph <- DiagrammeR::grViz(dot)
  if (identical(as, "diagrammer")) {
    return(graph)
  }
  if (!requireNamespace("DiagrammeRsvg", quietly = TRUE)) {
    stop(
      "`render_schema_shape_graphviz(..., as = \"svg\")` requires the `DiagrammeRsvg` package.",
      call. = FALSE
    )
  }
  DiagrammeRsvg::export_svg(graph)
}

#' Render a MemorySpec as Graphviz DOT, DiagrammeR, or SVG
#'
#' Renders memory fields and, optionally, the schema shape of each field. The
#' output is for inspection and review of memory design, not runtime memory
#' execution.
#'
#' @param x A [`MemorySpec`] object.
#' @param include_field_schemas Whether to include nested schema-shape nodes for
#'   each memory field's `schema`.
#' @param rankdir Graphviz rank direction, for example `"TB"` or `"LR"`.
#' @param as Output format: raw `"dot"` text, a `"diagrammer"` object, or
#'   exported `"svg"` text.
#' @param label_width Approximate wrapping width for node labels.
#' @param show_edge_labels Whether to show edge relation labels.
#' @param show_tooltips Whether to include Graphviz tooltip attributes.
#'
#' @return A Graphviz DOT string, `DiagrammeR` graph object, or SVG string.
#' @export
render_memory_schema_graphviz <- function(
  x,
  include_field_schemas = TRUE,
  rankdir = "TB",
  as = c("dot", "diagrammer", "svg"),
  label_width = 28,
  show_edge_labels = TRUE,
  show_tooltips = FALSE
) {
  as <- match.arg(as)
  graph_data <- memory_schema_graph_data(x, include_field_schemas = include_field_schemas)
  dot <- .schema_graph_dot(
    graph_data = graph_data,
    graph_name = "memory_schema",
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
      "`render_memory_schema_graphviz(..., as = \"diagrammer\")` requires the `DiagrammeR` package.",
      call. = FALSE
    )
  }
  graph <- DiagrammeR::grViz(dot)
  if (identical(as, "diagrammer")) {
    return(graph)
  }
  if (!requireNamespace("DiagrammeRsvg", quietly = TRUE)) {
    stop(
      "`render_memory_schema_graphviz(..., as = \"svg\")` requires the `DiagrammeRsvg` package.",
      call. = FALSE
    )
  }
  DiagrammeRsvg::export_svg(graph)
}
