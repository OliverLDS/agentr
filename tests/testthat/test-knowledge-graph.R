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
  expect_true("ki_gold_real_yields_001" %in% graph$nodes$id)
  expect_true("domain::macro_trading" %in% graph$nodes$id)
  expect_true("concept::real_yields" %in% graph$nodes$id)
  expect_true(any(graph$edges$relation == "condition"))
  expect_true(any(graph$edges$relation == "exception"))
  expect_true(any(graph$edges$relation == "has_cause"))
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

