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
  expect_true(grepl("graph-scroll", html, fixed = TRUE))
  expect_true(grepl("drawReviewGraph", html, fixed = TRUE))
  expect_true(grepl("prepareReviewEdgeLanes", html, fixed = TRUE))
  expect_true(grepl("reviewEdgeAnchor", html, fixed = TRUE))
  expect_true(grepl("nodeW:220", html, fixed = TRUE))
  expect_true(grepl("rowGap:42", html, fixed = TRUE))
  expect_false(grepl("id:'knowledge_spec'", html, fixed = TRUE))
  expect_false(grepl("from:'knowledge_spec'", html, fixed = TRUE))
  expect_true(grepl("Knowledge, memory, and resource schema", html, fixed = TRUE))
  expect_true(grepl("renderResourcePanel", html, fixed = TRUE))
  expect_true(grepl("relatedWorkflowResources", html, fixed = TRUE))
  expect_true(grepl("workflowActionNodes", html, fixed = TRUE))
  expect_true(grepl("id='resources'.*Detail inspector.*id='node_detail'.*Structured feedback", html))
  expect_true(grepl("subworkflow_modal", html, fixed = TRUE))
  expect_true(grepl("openSubworkflowModal", html, fixed = TRUE))
  expect_true(grepl("modal-layout", html, fixed = TRUE))
  expect_true(grepl("subworkflow_resources", html, fixed = TRUE))
  expect_true(grepl("subworkflow_node_detail", html, fixed = TRUE))
  expect_true(grepl("overflow:auto;overscroll-behavior-x:contain", html, fixed = TRUE))
  expect_true(grepl("svg{display:block;max-width:none}", html, fixed = TRUE))
  expect_true(grepl("const maxEdgeX=edges.length?", html, fixed = TRUE))
  expect_true(grepl("const viewRight=Math.max", html, fixed = TRUE))
  expect_true(grepl("Graph nodes show the action flow only", html, fixed = TRUE))
  expect_true(grepl("Deterministic automation", html, fixed = TRUE))
  expect_true(grepl("External stochastic LLM", html, fixed = TRUE))
  expect_false(grepl("https://", html, fixed = TRUE))
  expect_false(grepl("http://", html, fixed = TRUE))
})

test_that("design_review_html uses packaged renderer assets", {
  spec <- .test_complete_agent_spec()
  html <- design_review_html(spec, title = "Asset review")

  expect_true(file.exists(system.file("review", "design_review.js", package = "agentr", mustWork = FALSE)) ||
    file.exists(file.path("inst", "review", "design_review.js")))
  expect_true(grepl("function drawWorkflowGraph", html, fixed = TRUE))
  expect_true(grepl("function nodeKind", html, fixed = TRUE))
})

test_that("design_review_html supports workflow data nodes", {
  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node(
        id = "knowledge_rules",
        label = "Article style rules",
        node_kind = "knowledge",
        human_required = FALSE,
        source_path = "docs/knowledge_spec.yaml",
        retrieval_mode = "yaml_lookup",
        persistence = "static",
        linked_spec_ids = "knowledge_spec.yaml"
      ),
      workflow_node("build_prompt", "Build prompt", human_required = FALSE)
    ),
    edges = workflow_edge("knowledge_rules", "build_prompt", relation = "prompts_with"),
    task = "Data node review"
  )

  html <- design_review_html(workflow, title = "Data node review", graph_layout = "process")

  expect_true(grepl('"node_kind":"knowledge"', html, fixed = TRUE))
  expect_true(grepl("Knowledge data", html, fixed = TRUE))
  expect_true(grepl("Source path", html, fixed = TRUE))
  expect_true(grepl("prompts_with", html, fixed = TRUE))
  expect_true(grepl("Workflow resource linked by", html, fixed = TRUE))
  expect_true(grepl("resource -> action", html, fixed = TRUE))
  expect_true(grepl("workflowActionEdges", html, fixed = TRUE))
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

test_that("design_review_html inherits default categories from nested descendants", {
  nested <- new_workflow_spec(
    nodes = rbind(
      workflow_node("nested_human", "Human approval step", human_required = TRUE),
      workflow_node("nested_llm", "External LLM step", automation_status = "llm_assisted"),
      workflow_node("nested_auto", "Deterministic helper", automation_status = "agent_owned")
    ),
    edges = rbind(
      workflow_edge("nested_human", "nested_llm"),
      workflow_edge("nested_llm", "nested_auto")
    ),
    task = "Nested category review"
  )
  workflow <- new_workflow_spec(
    nodes = workflow_node(
      "parent_node",
      "Parent node with nested workflow",
      human_required = FALSE,
      automation_status = "agent_owned",
      nested_workflow = nested
    ),
    edges = .empty_workflow_edges(),
    task = "Parent category review"
  )
  html <- design_review_html(workflow, title = "Parent category review")

  expect_true(grepl("baseWorkflowCategory", html, fixed = TRUE))
  expect_true(grepl("categoryPriority", html, fixed = TRUE))
  expect_true(grepl("effectiveWorkflowCategory", html, fixed = TRUE))
  expect_true(grepl("Category", html, fixed = TRUE))
  expect_true(grepl("Graph nodes show the action flow only", html, fixed = TRUE))
})

test_that("design_review_html renders branch edge metadata visibly", {
  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node("route", "Route by source count"),
      workflow_node("single", "Single-source prompt"),
      workflow_node("multi", "Multi-source prompt")
    ),
    edges = rbind(
      workflow_edge(
        "route",
        "single",
        relation = "exclusive_branch",
        condition = "source_count == 1",
        branch_group = "source_count_route",
        mutually_exclusive = TRUE
      ),
      workflow_edge(
        "route",
        "multi",
        relation = "exclusive_branch",
        condition = "source_count > 1",
        branch_group = "source_count_route",
        mutually_exclusive = TRUE
      )
    ),
    task = "Branch review"
  )
  html <- design_review_html(workflow, title = "Branch review")

  expect_true(grepl('"condition":"source_count == 1"', html, fixed = TRUE))
  expect_true(grepl('"branch_group":"source_count_route"', html, fixed = TRUE))
  expect_true(grepl('"mutually_exclusive":true', html, fixed = TRUE))
  expect_true(grepl("function isBranchEdge", html, fixed = TRUE))
  expect_true(grepl("function edgeLabel", html, fixed = TRUE))
  expect_true(grepl("arrow-branch", html, fixed = TRUE))
  expect_true(grepl("stroke-dasharray='${visual.dash}'", html, fixed = TRUE))
  expect_true(grepl("<b>Condition</b>", html, fixed = TRUE))
  expect_true(grepl("<b>Branch group</b>", html, fixed = TRUE))
  expect_true(grepl("<b>Mutually exclusive</b>", html, fixed = TRUE))
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
  expect_true(grepl("ensureSubworkflowModal", html, fixed = TRUE))
  expect_true(grepl("openSubworkflowModal", html, fixed = TRUE))
  expect_true(grepl("data-subworkflow-id", html, fixed = TRUE))
  expect_true(grepl("sw_fb_target", html, fixed = TRUE))
  expect_true(grepl("addSubworkflowFeedback", html, fixed = TRUE))
  expect_true(grepl("renderSubworkflowResourcePanel", html, fixed = TRUE))
  expect_true(grepl("onNodeClick=onNodeClick||selectWorkflowNode", html, fixed = TRUE))
  expect_true(grepl("selectWorkflowNode", html, fixed = TRUE))
  expect_true(grepl("data-node-id", html, fixed = TRUE))
  expect_true(grepl("data-edge-index", html, fixed = TRUE))
  expect_true(grepl("renderEdgeDetailObject", html, fixed = TRUE))
  expect_true(grepl("Input schema", html, fixed = TRUE))
  expect_true(grepl("Output schema", html, fixed = TRUE))
  expect_true(grepl("Subworkflow", html, fixed = TRUE))
  expect_true(grepl("- subworkflow", html, fixed = TRUE))
  expect_true(grepl("function hasSubworkflow", html, fixed = TRUE))
  expect_true(grepl("val(n.subworkflow_ref)", html, fixed = TRUE))
  expect_true(grepl("e.stopPropagation()", html, fixed = TRUE))
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

test_that("design_review_html process layout places branch targets in decision blocks", {
  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node("start", "Start"),
      workflow_node("route", "Route by source count"),
      workflow_node("single", "Single-source path"),
      workflow_node("multi", "Multi-source path"),
      workflow_node("join", "Continue after branch")
    ),
    edges = rbind(
      workflow_edge("start", "route"),
      workflow_edge(
        "route",
        "single",
        relation = "exclusive_branch",
        condition = "source_count == 1",
        branch_group = "source_count_route",
        mutually_exclusive = TRUE
      ),
      workflow_edge(
        "route",
        "multi",
        relation = "exclusive_branch",
        condition = "source_count > 1",
        branch_group = "source_count_route",
        mutually_exclusive = TRUE
      ),
      workflow_edge("single", "join"),
      workflow_edge("multi", "join")
    ),
    task = "Branch process review"
  )
  html <- design_review_html(workflow, graph_layout = "process", edge_style = "orthogonal")

  expect_true(grepl("branchBySource", html, fixed = TRUE))
  expect_true(grepl("isBranchEdge(e)", html, fixed = TRUE))
  expect_true(grepl("branchIds.add(e.to)", html, fixed = TRUE))
  expect_true(grepl("decisionJoinIds", html, fixed = TRUE))
  expect_true(grepl("decisionJoinBySource", html, fixed = TRUE))
  expect_true(grepl("_decisionJoin", html, fixed = TRUE))
  expect_true(grepl("_processBranchLane", html, fixed = TRUE))
  expect_true(grepl("branchGap=Math.max(opt.colGap,320)", html, fixed = TRUE))
  expect_true(grepl("startX=n._x-((count-1)*branchGap)/2", html, fixed = TRUE))
  expect_true(grepl("y=Math.max(y,join._y+join._h+opt.rowGap)", html, fixed = TRUE))
  expect_true(grepl("_processBranchSource", html, fixed = TRUE))
  expect_true(grepl("_branchRejoin", html, fixed = TRUE))
  expect_true(grepl("_branchRejoinSide", html, fixed = TRUE))
  expect_true(grepl("_branchRailX", html, fixed = TRUE))
  expect_true(grepl("_feedbackRailX", html, fixed = TRUE))
  expect_true(grepl("edgeLabelPosition(a,b,e)", html, fixed = TRUE))
  expect_true(grepl("isBranchEdge(e)&&b._processBranch&&!e._branchRejoin", html, fixed = TRUE))
  expect_true(grepl("const startX=left?a._x:a._x+nodeW", html, fixed = TRUE))
  expect_true(grepl("const endX=b._x+nodeW/2", html, fixed = TRUE))
  expect_true(grepl("const endY=b._y", html, fixed = TRUE))
  expect_true(grepl("e._branchRejoin", html, fixed = TRUE))
  expect_true(grepl("edgePath(a,b,opt.nodeW,config.edge_style,i,e)", html, fixed = TRUE))
  expect_true(grepl('"condition":"source_count == 1"', html, fixed = TRUE))
  expect_true(grepl('"condition":"source_count > 1"', html, fixed = TRUE))
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
