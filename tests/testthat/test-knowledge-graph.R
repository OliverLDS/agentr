test_that("knowledge_graph_from_spec builds graph data from KnowledgeSpec", {
  ks <- KnowledgeSpec$new(items = list(
    list(
      id = "ki_gold_real_yields_001",
      type = "causal_relation",
      raw_statement = "Gold often falls when real yields rise.",
      normalized_statement = "In normal market regimes, rising real yields tend to pressure gold prices.",
      domain = "macro_trading",
      confidence = "medium",
      review = list(status = "approved")
    )
  ))

  graph <- knowledge_graph_from_spec(ks)

  expect_true(is.data.frame(graph$nodes))
  expect_true(is.data.frame(graph$edges))
  expect_equal(graph$metadata$source, "knowledge_spec_projection")
  expect_true("ki_gold_real_yields_001" %in% graph$nodes$id)
  expect_true("domain::macro_trading" %in% graph$nodes$id)
  expect_true(any(graph$edges$relation == "domain"))
})

test_that("KnowledgeSpec can contain narrative items, graph representation, and vector refs", {
  graph <- list(
    nodes = list(
      list(id = "react", label = "ReAct", node_type = "concept", memory_type = "semantic"),
      list(id = "observe_decide_act", label = "observe-decide-act", node_type = "concept", memory_type = "procedural")
    ),
    edges = list(
      list(
        from = "react",
        to = "observe_decide_act",
        relation = "implements_part_of",
        relation_type = "implements_part_of",
        memory_type = "procedural"
      )
    ),
    metadata = list(graph_mode = "curated")
  )

  ks <- KnowledgeSpec$new(
    items = list(list(
      id = "ki_react_001",
      type = "concept",
      raw_statement = "ReAct combines reasoning and acting.",
      normalized_statement = "ReAct combines reasoning traces with action/tool-use steps.",
      review = list(status = "approved")
    )),
    graph = graph,
    vector_refs = list(
      paper_embeddings = list(store = "external", collection = "agent_papers")
    )
  )

  expect_true(is.list(ks$graph))
  expect_equal(length(ks$items), 1L)
  expect_equal(length(ks$vector_refs), 1L)
  expect_equal(ks$graph$edges[[1]]$relation, "implements_part_of")
  expect_equal(ks$to_list()$graph$metadata$graph_mode, "curated")
})

test_that("MemorySpec can contain graph-shaped memory", {
  graph <- list(
    nodes = list(
      list(id = "event_1", label = "First run", node_type = "event", memory_type = "episodic")
    ),
    edges = list(),
    metadata = list(source = "runtime_trace")
  )
  memory <- MemorySpec$new(
    fields = list(memory_field("run_history", "Run history", memory_type = "episodic")),
    graph = graph
  )

  graph_data <- knowledge_graph_data(memory)
  expect_true(is.data.frame(graph_data$nodes))
  expect_equal(graph_data$nodes$id[[1]], "event_1")
  expect_equal(memory$to_list()$graph$metadata$source, "runtime_trace")
})

test_that("knowledge graph rendering returns DOT and optional DiagrammeR/SVG output", {
  ks <- KnowledgeSpec$new(items = list(
    list(
      id = "ki_chart_rule_001",
      type = "rule",
      raw_statement = "Avoid dual-axis charts unless there is a clear interpretive gain.",
      normalized_statement = "Avoid dual-axis charts unless the interpretive gain is explicit and justified.",
      domain = "macro_analysis",
      review = list(status = "approved")
    )
  ))

  dot <- render_knowledge_graphviz(ks, as = "dot")

  expect_true(is.character(dot))
  expect_true(grepl("digraph knowledge", dot, fixed = TRUE))
  expect_true(grepl("\"ki_chart_rule_001\"", dot, fixed = TRUE))
  expect_true(grepl("domain", dot, fixed = TRUE))

  graph_data <- knowledge_graph_data(ks)
  expect_true(is.data.frame(graph_data$nodes))
  expect_true(is.data.frame(graph_data$edges))

  if (requireNamespace("DiagrammeR", quietly = TRUE)) {
    rendered <- render_knowledge_graphviz(ks, as = "diagrammer")
    expect_true(inherits(rendered, "grViz"))
  } else {
    expect_error(
      render_knowledge_graphviz(ks, as = "diagrammer"),
      "requires the `DiagrammeR` package"
    )
  }

  if (requireNamespace("DiagrammeR", quietly = TRUE) && requireNamespace("DiagrammeRsvg", quietly = TRUE)) {
    svg <- render_knowledge_graphviz(ks, as = "svg")
    expect_true(is.character(svg))
    expect_true(grepl("<svg", svg, fixed = TRUE))
  } else if (requireNamespace("DiagrammeR", quietly = TRUE)) {
    expect_error(
      render_knowledge_graphviz(ks, as = "svg"),
      "requires the `DiagrammeRsvg` package"
    )
  }
})
