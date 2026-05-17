test_that("KnowledgeGraphProposalState supports discuss, approve, reject, and supersede", {
  graph_1 <- new_knowledge_graph_spec()
  graph_1 <- add_knowledge_graph_node(graph_1, "act_r", "ACT-R", node_type = "concept", memory_type = "semantic")

  graph_2 <- new_knowledge_graph_spec()
  graph_2 <- add_knowledge_graph_node(graph_2, "bdi", "BDI", node_type = "concept", memory_type = "semantic")
  graph_2 <- add_knowledge_graph_node(graph_2, "belief", "Belief", node_type = "concept", memory_type = "semantic")
  graph_2 <- add_knowledge_graph_edge(graph_2, "bdi", "belief", relation = "has_component", relation_type = "has_component", memory_type = "semantic")

  state <- KnowledgeGraphProposalState$new()
  state$add_proposal(KnowledgeGraphProposal$new(id = "graph_proposal_1", graph = graph_1))
  state$add_proposal(KnowledgeGraphProposal$new(id = "graph_proposal_2", graph = graph_2))
  state$discuss_proposal("graph_proposal_1", "Need components too.")
  approved <- state$approve_proposal("graph_proposal_2")

  expect_true(inherits(approved, "KnowledgeGraphProposal"))
  expect_equal(state$get_proposal("graph_proposal_2")$status, "approved")
  expect_equal(state$get_proposal("graph_proposal_1")$status, "superseded")
  expect_equal(state$approved_spec()$edges$relation[[1]], "has_component")
})

test_that("knowledge graph prompts and messages support preview and apply", {
  state <- KnowledgeGraphProposalState$new()
  prompt <- build_knowledge_graph_extraction_prompt("ACT-R is a cognitive architecture.", format = "json")
  expect_true(grepl("\"knowledge_graph_extractor\"", prompt, fixed = TRUE))

  message <- jsonlite::toJSON(list(actions = list(list(
    method = "propose_knowledge_graph",
    args = list(
      proposal_id = "graph_proposal_json",
      graph = list(
        nodes = list(
          list(id = "act_r", label = "ACT-R", node_type = "concept", memory_type = "semantic"),
          list(id = "cognitive_architecture", label = "cognitive architecture", node_type = "concept", memory_type = "semantic")
        ),
        edges = list(list(
          from = "act_r",
          to = "cognitive_architecture",
          relation = "is_a",
          relation_type = "is_a",
          memory_type = "semantic",
          confidence = 0.95
        )),
        metadata = list(graph_mode = "curated")
      )
    )
  ))), auto_unbox = TRUE)

  preview <- preview_knowledge_graph_message(state, message)
  expect_equal(preview$proposal_count, 0L)

  apply_knowledge_graph_message(state, message)
  expect_equal(length(state$proposals), 1L)
  expect_equal(state$get_proposal("graph_proposal_json")$graph$edges$relation[[1]], "is_a")

  apply_knowledge_graph_message(state, jsonlite::toJSON(list(actions = list(list(
    method = "approve_knowledge_graph_proposal",
    args = list(proposal_id = "graph_proposal_json")
  ))), auto_unbox = TRUE))

  expect_equal(state$approved_spec()$edges$relation_type[[1]], "is_a")
})

test_that("knowledge graph messages reject unsupported or unsafe actions", {
  expect_error(
    parse_knowledge_graph_message('{"actions":[{"method":"exec_graph_code","args":{}}]}'),
    "Unsupported knowledge graph action"
  )
})

