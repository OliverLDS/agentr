test_that("knowledge_graph_from_spec builds graph spec from KnowledgeSpec", {
  ks <- KnowledgeSpec$new(items = list(
    list(
      id = "ki_gold_real_yields_001",
      type = "causal_relation",
      raw_statement = "Gold often falls when real yields rise.",
      normalized_statement = "In normal market regimes, rising real yields tend to pressure gold prices.",
      domain = "macro_trading",
      structure = list(
        cause = "real_yields",
        effect = "gold_price",
        direction = "negative"
      ),
      conditions = c("normal market regime"),
      exceptions = c("safe-haven demand"),
      confidence = "medium",
      review = list(status = "approved")
    )
  ))

  graph <- knowledge_graph_from_spec(ks)

  expect_s3_class(graph, "agentr_knowledge_graph_spec")
  expect_equal(graph$metadata$graph_mode, "projection")
  expect_true("ki_gold_real_yields_001" %in% graph$nodes$id)
  expect_true("domain::macro_trading" %in% graph$nodes$id)
  expect_true("concept::real_yields" %in% graph$nodes$id)
  expect_true(all(graph$nodes$knowledge_form == "projection"))
  expect_true(all(graph$nodes$memory_type == "semantic"))
  expect_true(any(graph$edges$relation == "condition"))
  expect_true(any(graph$edges$relation == "exception"))
  expect_true(any(graph$edges$relation == "has_cause"))
})

test_that("knowledge graph spec can store first-class graph knowledge", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  graph <- new_knowledge_graph_spec(metadata = list(graph_mode = "curated"))
  graph <- add_knowledge_graph_node(
    graph,
    id = "act_r",
    label = "ACT-R",
    node_type = "concept",
    memory_type = "semantic",
    provenance = list(source = "human"),
    review = list(status = "approved"),
    scope = list(domain = "cognitive_architectures")
  )
  graph <- add_knowledge_graph_node(
    graph,
    id = "cognitive_architecture",
    label = "cognitive architecture",
    node_type = "concept",
    memory_type = "semantic",
    review = list(status = "approved")
  )
  graph <- add_knowledge_graph_edge(
    graph,
    from = "act_r",
    to = "cognitive_architecture",
    relation = "is_a",
    relation_type = "is_a",
    memory_type = "semantic",
    confidence = 0.95,
    review = list(status = "approved"),
    scope = list(domain = "cognitive_architectures")
  )

  expect_s3_class(graph, "agentr_knowledge_graph_spec")
  expect_equal(graph$nodes$knowledge_form[[1]], "graph")
  expect_equal(graph$nodes$memory_type[[1]], "semantic")
  expect_equal(graph$nodes$review[[1]]$status, "approved")
  expect_equal(graph$edges$relation_type[[1]], "is_a")
  expect_equal(graph$edges$memory_type[[1]], "semantic")

  save_knowledge_graph_spec(graph, path)
  loaded <- load_knowledge_graph_spec(path)
  expect_s3_class(loaded, "agentr_knowledge_graph_spec")
  expect_equal(loaded$edges$relation[[1]], "is_a")
})

test_that("KnowledgeSpec can contain narrative items, graph knowledge, and vector refs", {
  graph <- new_knowledge_graph_spec(
    nodes = rbind(
      knowledge_graph_node("react", "ReAct", node_type = "concept", memory_type = "semantic"),
      knowledge_graph_node("observe_decide_act", "observe-decide-act", node_type = "concept", memory_type = "procedural")
    ),
    edges = knowledge_graph_edge(
      "react",
      "observe_decide_act",
      relation = "implements_part_of",
      relation_type = "implements_part_of",
      memory_type = "procedural"
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

  expect_true(inherits(ks$graph, "agentr_knowledge_graph_spec"))
  expect_equal(length(ks$items), 1L)
  expect_equal(length(ks$vector_refs), 1L)
  expect_equal(ks$graph$edges$relation[[1]], "implements_part_of")
  expect_equal(ks$to_list()$graph$metadata$graph_mode, "curated")
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
  expect_true(grepl("in_domain", dot, fixed = TRUE))

  graph_data <- knowledge_graph_data(ks)
  expect_true(is.data.frame(graph_data$vertices))
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
