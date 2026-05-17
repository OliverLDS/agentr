test_that("MemoryProposalState supports discuss, approve, reject, and supersede", {
  state <- MemoryProposalState$new()
  proposal_1 <- MemoryProposal$new(
    id = "memory_proposal_1",
    memory_spec = MemorySpec$new(fields = list(memory_field(
      id = "context_state",
      label = "Context state",
      memory_type = "context",
      persistence = "session"
    )))
  )
  proposal_2 <- MemoryProposal$new(
    id = "memory_proposal_2",
    memory_spec = MemorySpec$new(fields = list(memory_field(
      id = "semantic_terms",
      label = "Semantic terms",
      memory_type = "semantic",
      persistence = "cold_start_rds"
    )))
  )

  state$add_proposal(proposal_1)
  state$add_proposal(proposal_2)
  state$discuss_proposal("memory_proposal_1", "Clarify persistence.")
  approved <- state$approve_proposal("memory_proposal_2")

  expect_true(inherits(approved, "MemoryProposal"))
  expect_equal(state$get_proposal("memory_proposal_2")$status, "approved")
  expect_equal(state$get_proposal("memory_proposal_1")$status, "superseded")
  expect_equal(state$approved_spec()$get_field("semantic_terms")$memory_type, "semantic")
})

test_that("memory prompts and messages support preview and apply", {
  state <- MemoryProposalState$new()
  prompt <- build_memory_schema_prompt("Design memory for a paper-reading agent.", format = "json")
  expect_true(grepl("\"memory_schema_designer\"", prompt, fixed = TRUE))

  message <- jsonlite::toJSON(list(actions = list(list(
    method = "propose_memory_schema",
    args = list(
      proposal_id = "memory_proposal_json",
      memory_spec = list(
        fields = list(list(
          id = "paper_context",
          label = "Paper context",
          memory_type = "context",
          description = "Current paper paragraph and user question.",
          schema = list(fields = list("paper_id", "paragraph_id", "question")),
          persistence = "session"
        )),
        metadata = list(source = "model")
      ),
      notes = "Initial schema"
    )
  ))), auto_unbox = TRUE)

  preview <- preview_memory_message(state, message)
  expect_equal(preview$proposal_count, 0L)

  apply_memory_message(state, message)
  expect_equal(length(state$proposals), 1L)
  expect_equal(state$get_proposal("memory_proposal_json")$memory_spec$get_field("paper_context")$memory_type, "context")

  apply_memory_message(state, jsonlite::toJSON(list(actions = list(list(
    method = "approve_memory_proposal",
    args = list(proposal_id = "memory_proposal_json")
  ))), auto_unbox = TRUE))

  expect_equal(state$approved_spec()$get_field("paper_context")$persistence, "session")
})

test_that("memory messages reject unsupported or unsafe actions", {
  expect_error(
    parse_memory_message('{"actions":[{"method":"run_code","args":{}}]}'),
    "Unsupported memory action"
  )
})

