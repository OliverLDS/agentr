test_that("design_review_html returns standalone review page", {
  spec <- .test_complete_agent_spec()
  html <- design_review_html(spec, title = "Fixture review")

  expect_true(is.character(html))
  expect_length(html, 1L)
  expect_true(grepl("Fixture review", html, fixed = TRUE))
  expect_true(grepl("agentr-review-data", html, fixed = TRUE))
  expect_true(grepl("Workflow graph", html, fixed = TRUE))
  expect_true(grepl("Structured feedback", html, fixed = TRUE))
  expect_true(grepl("memory_schema", html, fixed = TRUE))
  expect_true(grepl("splitter", html, fixed = TRUE))
  expect_true(grepl("feedback-section-gap", html, fixed = TRUE))
  expect_true(grepl("initSplit", html, fixed = TRUE))
  expect_true(grepl("workflow-theme-select", html, fixed = TRUE))
  expect_true(grepl("subsystemPalette", html, fixed = TRUE))
  expect_true(grepl("Graph nodes represent the reviewed task workflow, including external scripts and external LLM steps.", html, fixed = TRUE))
  expect_false(grepl("https://", html, fixed = TRUE))
  expect_false(grepl("http://", html, fixed = TRUE))
})

test_that("design_review_html supports subsystem-based node color theme", {
  spec <- .test_complete_agent_spec()
  html <- design_review_html(spec, node_color_theme = "subsystems")

  expect_true(grepl('"node_color_theme":"subsystems"', html, fixed = TRUE))
  expect_true(grepl("nodeColorTheme", html, fixed = TRUE))
  expect_true(grepl("nodeSubsystem", html, fixed = TRUE))
  expect_true(grepl("renderWorkflowLegend", html, fixed = TRUE))
  expect_true(grepl("applyWorkflowTheme", html, fixed = TRUE))
  expect_true(grepl("'RWM'", html, fixed = TRUE) || grepl("label:'RWM'", html, fixed = TRUE))
  expect_true(grepl("node_subsystems", html, fixed = TRUE))
  expect_true(grepl('"node_refresh"', html, fixed = TRUE))
  expect_true(grepl('"node_interpret"', html, fixed = TRUE))
})

test_that("design_review_html shows node detail schemas and nested workflow drilldown", {
  nested <- new_workflow_spec(
    nodes = rbind(
      workflow_node("nested_1", "Read input"),
      workflow_node("nested_2", "Return output")
    ),
    edges = workflow_edge("nested_1", "nested_2"),
    task = "Nested task"
  )
  workflow <- new_workflow_spec(
    nodes = workflow_node(
      "node_detail",
      "High-level step with nested workflow",
      rule_spec = "Use the nested workflow for detailed review.",
      implementation_hint = "Return JSON with answer and confidence.",
      owner = "human",
      automation_status = "human_in_loop",
      knowledge_refs = "ki_nested",
      subworkflow_ref = "workflows/node_detail.json",
      input_schema = list(type = "object", required = "question"),
      output_schema = list(type = "object", properties = list(answer = "string")),
      nested_workflow = nested
    ),
    edges = .empty_workflow_edges(),
    task = "Node detail review"
  )
  html <- design_review_html(workflow, title = "Node detail review")

  expect_true(grepl("Detail inspector", html, fixed = TRUE))
  expect_true(grepl("renderNodeDetail", html, fixed = TRUE))
  expect_true(grepl("renderNestedNodeDetail", html, fixed = TRUE))
  expect_true(grepl("renderTaskTabs", html, fixed = TRUE))
  expect_true(grepl("Task previews", html, fixed = TRUE))
  expect_true(grepl("task-tab", html, fixed = TRUE))
  expect_true(grepl("onNodeClick=onNodeClick||selectWorkflowNode", html, fixed = TRUE))
  expect_true(grepl("selectWorkflowNode", html, fixed = TRUE))
  expect_true(grepl("data-node-id", html, fixed = TRUE))
  expect_true(grepl("data-edge-index", html, fixed = TRUE))
  expect_true(grepl("renderEdgeDetailObject", html, fixed = TRUE))
  expect_true(grepl("Input schema", html, fixed = TRUE))
  expect_true(grepl("Output schema", html, fixed = TRUE))
  expect_true(grepl("Nested workflow", html, fixed = TRUE))
  expect_true(grepl("workflows/node_detail.json", html, fixed = TRUE))
  expect_true(grepl("function knowledgeRefs", html, fixed = TRUE))
  expect_true(grepl("function arrayValue", html, fixed = TRUE))
  expect_true(grepl("knowledgeRefs(n.knowledge_refs).join(', ')", html, fixed = TRUE))
  expect_true(grepl('"knowledge_refs":["ki_nested"]', html, fixed = TRUE))
  expect_true(grepl('"input_schema":{"type":"object","required":["question"]}', html, fixed = TRUE))
  expect_true(grepl('"output_schema":{"type":"object","properties":{"answer":"string"}}', html, fixed = TRUE))
  expect_true(grepl('"nested_workflow":{"nodes"', html, fixed = TRUE))
  expect_false(grepl("font-size='11'>${esc(n.id)}</text>", html, fixed = TRUE))
  expect_false(grepl("owner: ${esc(val(n.owner))} | automation: ${esc(val(n.automation_status))}", html, fixed = TRUE))
  expect_false(grepl("human gate: ${esc(n.human_required)} | review: ${esc(val(n.review_status))}", html, fixed = TRUE))
  expect_false(grepl("knowledge refs: ${esc(knowledgeRefs(n.knowledge_refs).join(', '))}", html, fixed = TRUE))
  expect_false(grepl("<h3>Edges</h3>", html, fixed = TRUE))
  expect_false(grepl("d.className='edge';", html, fixed = TRUE))
})

test_that("design_review_html wraps workflow graph labels without truncation", {
  long_label <- "Select the most appropriate chart type for the economic analysis and document why alternatives were rejected"
  workflow <- new_workflow_spec(
    nodes = workflow_node("node_long", long_label),
    edges = .empty_workflow_edges(),
    task = "Long label review"
  )
  html <- design_review_html(workflow, title = "Long label review")

  expect_false(grepl("slice(0,24)", html, fixed = TRUE))
  expect_true(grepl("wrapSvgText", html, fixed = TRUE))
  expect_true(grepl("<tspan", html, fixed = TRUE))
  expect_true(grepl("_cy=n._y+n._h/2", html, fixed = TRUE))
  expect_true(grepl("overflow-wrap:anywhere", html, fixed = TRUE))
  expect_true(grepl(long_label, html, fixed = TRUE))
})

test_that("design_review_html supports layered layout and routed edge paths", {
  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node("node_a", "Start"),
      workflow_node("node_b", "Middle"),
      workflow_node("node_c", "End")
    ),
    edges = rbind(
      workflow_edge("node_a", "node_b"),
      workflow_edge("node_a", "node_c")
    ),
    task = "Layered graph review"
  )
  html <- design_review_html(workflow, graph_layout = "layered", edge_style = "orthogonal")

  expect_true(grepl("layoutWorkflowLayered", html, fixed = TRUE))
  expect_true(grepl("processed.size<nodes.length", html, fixed = TRUE))
  expect_true(grepl("order[e.to]>order[e.from]", html, fixed = TRUE))
  expect_true(grepl("const maxCols=4", html, fixed = TRUE))
  expect_true(grepl("edgeAnchors", html, fixed = TRUE))
  expect_true(grepl("edgePath", html, fixed = TRUE))
  expect_true(grepl("const feedback=", html, fixed = TRUE))
  expect_true(grepl("<path d=", html, fixed = TRUE))
  expect_true(grepl("axis:'vertical'", html, fixed = TRUE))
  expect_true(grepl("Math.abs(sx-tx)<2", html, fixed = TRUE))
  expect_true(grepl('"graph_layout":"layered"', html, fixed = TRUE))
  expect_true(grepl('"edge_style":"orthogonal"', html, fixed = TRUE))
})

test_that("design_review_html layered layout includes cycle-tolerant feedback handling", {
  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node("node_1", "Start"),
      workflow_node("node_2", "Filter"),
      workflow_node("node_3", "Select next or terminate"),
      workflow_node("node_4", "Do work"),
      workflow_node("node_9", "Update store"),
      workflow_node("node_10", "Summarize")
    ),
    edges = rbind(
      workflow_edge("node_1", "node_2"),
      workflow_edge("node_2", "node_3"),
      workflow_edge("node_3", "node_4"),
      workflow_edge("node_3", "node_10"),
      workflow_edge("node_4", "node_9"),
      workflow_edge("node_9", "node_3")
    ),
    task = "Loop graph review"
  )
  html <- design_review_html(workflow, graph_layout = "layered", edge_style = "orthogonal")

  expect_true(grepl('"from":"node_3","to":"node_4"', html, fixed = TRUE))
  expect_true(grepl('"from":"node_3","to":"node_10"', html, fixed = TRUE))
  expect_true(grepl('"from":"node_9","to":"node_3"', html, fixed = TRUE))
  expect_true(grepl("processed.size<nodes.length", html, fixed = TRUE))
  expect_true(grepl("order[e.to]>order[e.from]", html, fixed = TRUE))
  expect_true(grepl("const maxCols=4", html, fixed = TRUE))
  expect_true(grepl("const feedback=", html, fixed = TRUE))
  expect_true(grepl('Use graph_layout = "process"', html, fixed = TRUE))
})

test_that("design_review_html supports process layout for loop workflows", {
  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node("node_1", "Start"),
      workflow_node("node_2", "Filter"),
      workflow_node("node_3", "Select next pending item or terminate"),
      workflow_node("node_4", "Process current item"),
      workflow_node("node_9", "Update store"),
      workflow_node("node_10", "Summarize run")
    ),
    edges = rbind(
      workflow_edge("node_1", "node_2"),
      workflow_edge("node_2", "node_3"),
      workflow_edge("node_3", "node_4"),
      workflow_edge("node_3", "node_10"),
      workflow_edge("node_4", "node_9"),
      workflow_edge("node_9", "node_3")
    ),
    task = "Process graph review"
  )
  html <- design_review_html(workflow, graph_layout = "process", edge_style = "orthogonal")

  expect_true(grepl("layoutWorkflowProcess", html, fixed = TRUE))
  expect_true(grepl("hasBackwardEdges", html, fixed = TRUE))
  expect_true(grepl("_processBranch", html, fixed = TRUE))
  expect_true(grepl("_processIndex", html, fixed = TRUE))
  expect_true(grepl("sameProcessColumn", html, fixed = TRUE))
  expect_true(grepl("const startX=sameProcessColumn?a._x", html, fixed = TRUE))
  expect_true(grepl("const endX=sameProcessColumn?b._x", html, fixed = TRUE))
  expect_true(grepl("railX", html, fixed = TRUE))
  expect_true(grepl('"graph_layout":"process"', html, fixed = TRUE))
})

test_that("design_review_html supports swimlane layout", {
  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node("node_human", "Human review", owner = "human"),
      workflow_node("node_script", "Script update", owner = "script"),
      workflow_node("node_agent", "Agent reasoning", owner = "agent")
    ),
    edges = rbind(
      workflow_edge("node_human", "node_script"),
      workflow_edge("node_script", "node_agent")
    ),
    task = "Swimlane graph review"
  )
  html <- design_review_html(workflow, graph_layout = "swimlane", edge_style = "curved")

  expect_true(grepl("layoutWorkflowSwimlane", html, fixed = TRUE))
  expect_true(grepl("laneLabel", html, fixed = TRUE))
  expect_true(grepl("colGroups", html, fixed = TRUE))
  expect_true(grepl("'owner: '+owner", html, fixed = TRUE))
  expect_true(grepl('"owner":"human"', html, fixed = TRUE))
  expect_true(grepl("overflow:auto", html, fixed = TRUE))
  expect_true(grepl("width='${w}'", html, fixed = TRUE))
  expect_true(grepl('"graph_layout":"swimlane"', html, fixed = TRUE))
})

test_that("export_design_review_html writes a file", {
  spec <- .test_complete_agent_spec()
  path <- tempfile(fileext = ".html")

  out <- export_design_review_html(spec, path, title = "Exported review")

  expect_equal(out, normalizePath(path, mustWork = FALSE))
  expect_true(file.exists(path))
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Exported review", txt, fixed = TRUE))
  expect_true(grepl("download JSON", txt, ignore.case = TRUE))
})
