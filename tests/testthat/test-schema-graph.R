test_that("schema_shape_graph_data builds graph data for nested schema lists", {
  schema <- list(
    type = "object",
    required = c("task_id", "status"),
    properties = list(
      task_id = list(type = "string"),
      status = list(enum = c("open", "closed")),
      metrics = list(
        type = "array",
        items = list(
          type = "object",
          properties = list(name = list(type = "string"), value = list(type = "number"))
        )
      )
    )
  )

  graph_data <- schema_shape_graph_data(schema, root_id = "output_schema", root_label = "Output schema")

  expect_true(is.data.frame(graph_data$vertices))
  expect_true(is.data.frame(graph_data$edges))
  expect_true("output_schema" %in% graph_data$vertices$id)
  expect_true(any(graph_data$vertices$label == "properties"))
  expect_true(any(graph_data$vertices$label == "task_id"))
  expect_true(any(graph_data$edges$relation == "field"))

  dot <- render_schema_shape_graphviz(schema, root_id = "output_schema", root_label = "Output schema", as = "dot")
  expect_true(is.character(dot))
  expect_true(grepl("digraph schema_shape", dot, fixed = TRUE))
  expect_true(grepl("Output schema", dot, fixed = TRUE))
  expect_true(grepl("task_id", dot, fixed = TRUE))
})

test_that("memory_schema_graph_data builds graph data with field schemas", {
  memory_spec <- MemorySpec$new(fields = list(
    memory_field(
      id = "current_task",
      label = "Current task",
      memory_type = "context",
      description = "Current user task and active document.",
      schema = list(
        type = "object",
        required = c("task_id"),
        properties = list(task_id = list(type = "string"))
      ),
      persistence = "session"
    ),
    memory_field(
      id = "concepts",
      label = "Approved concepts",
      memory_type = "semantic",
      description = "Approved concept definitions.",
      schema = list(fields = c("term", "definition")),
      persistence = "cold_start_rds"
    )
  ))

  graph_data <- memory_schema_graph_data(memory_spec)

  expect_true(is.data.frame(graph_data$vertices))
  expect_true(is.data.frame(graph_data$edges))
  expect_true("memory_schema" %in% graph_data$vertices$id)
  expect_true("field::current_task" %in% graph_data$vertices$id)
  expect_true(any(graph_data$edges$relation == "has_field"))
  expect_true(any(graph_data$edges$relation == "has_schema"))
  expect_true(any(graph_data$vertices$memory_type == "context", na.rm = TRUE))

  dot <- render_memory_schema_graphviz(memory_spec, as = "dot")
  expect_true(is.character(dot))
  expect_true(grepl("digraph memory_schema", dot, fixed = TRUE))
  expect_true(grepl("Current task", dot, fixed = TRUE))
  expect_true(grepl("has_schema", dot, fixed = TRUE))
})

test_that("schema graph renderers return optional DiagrammeR and SVG outputs when available", {
  schema <- list(type = "object", properties = list(id = list(type = "string")))
  memory_spec <- MemorySpec$new(fields = list(
    memory_field(
      id = "current_task",
      label = "Current task",
      memory_type = "context",
      schema = schema,
      persistence = "session"
    )
  ))

  if (requireNamespace("DiagrammeR", quietly = TRUE)) {
    rendered_schema <- render_schema_shape_graphviz(schema, as = "diagrammer")
    rendered_memory <- render_memory_schema_graphviz(memory_spec, as = "diagrammer")
    expect_true(inherits(rendered_schema, "grViz"))
    expect_true(inherits(rendered_memory, "grViz"))
  } else {
    expect_error(
      render_schema_shape_graphviz(schema, as = "diagrammer"),
      "requires the `DiagrammeR` package"
    )
    expect_error(
      render_memory_schema_graphviz(memory_spec, as = "diagrammer"),
      "requires the `DiagrammeR` package"
    )
  }

  if (requireNamespace("DiagrammeR", quietly = TRUE) && requireNamespace("DiagrammeRsvg", quietly = TRUE)) {
    schema_svg <- render_schema_shape_graphviz(schema, as = "svg")
    memory_svg <- render_memory_schema_graphviz(memory_spec, as = "svg")
    expect_true(is.character(schema_svg))
    expect_true(is.character(memory_svg))
    expect_true(grepl("<svg", schema_svg, fixed = TRUE))
    expect_true(grepl("<svg", memory_svg, fixed = TRUE))
  } else if (requireNamespace("DiagrammeR", quietly = TRUE)) {
    expect_error(
      render_schema_shape_graphviz(schema, as = "svg"),
      "requires the `DiagrammeRsvg` package"
    )
    expect_error(
      render_memory_schema_graphviz(memory_spec, as = "svg"),
      "requires the `DiagrammeRsvg` package"
    )
  }
})
