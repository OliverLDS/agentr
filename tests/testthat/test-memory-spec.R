test_that("MemorySpec initializes, validates, filters, and round-trips", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  spec <- MemorySpec$new()
  expect_true(inherits(spec, "MemorySpec"))
  expect_equal(length(spec$fields), 0L)

  spec$add_field(memory_field(
    id = "current_task_state",
    label = "Current task state",
    memory_type = "context",
    description = "Short-lived state for the current task.",
    schema = list(fields = c("task_id", "active_paragraph")),
    persistence = "session",
    update_policy = list(updated_by = "scaffolder")
  ))
  spec$add_field(memory_field(
    id = "paper_concepts",
    label = "Paper concepts",
    memory_type = "semantic",
    description = "Approved concepts from reviewed papers.",
    schema = list(fields = c("term", "definition", "source")),
    persistence = "cold_start_rds",
    review = list(status = "approved")
  ))

  expect_equal(length(spec$fields), 2L)
  expect_equal(spec$get_field("paper_concepts")$memory_type, "semantic")
  expect_equal(length(spec$list_fields(memory_type = "context")), 1L)
  expect_equal(length(spec$list_fields(persistence = "cold_start_rds")), 1L)

  expect_error(
    spec$add_field(spec$get_field("paper_concepts")),
    "Duplicate memory field id"
  )

  save_memory_spec(spec, path)
  loaded <- load_memory_spec(path)
  expect_true(inherits(loaded, "MemorySpec"))
  expect_equal(length(loaded$fields), 2L)
  expect_equal(loaded$get_field("paper_concepts")$review$status, "approved")
})

test_that("MemorySpec rejects invalid memory type, persistence, and review status", {
  expect_error(
    memory_field("bad_type", "Bad type", memory_type = "working"),
    "should be one of"
  )
  expect_error(
    memory_field("bad_persistence", "Bad persistence", persistence = "sqlite"),
    "should be one of"
  )
  expect_error(
    memory_field("bad_review", "Bad review", review = list(status = "done")),
    "should be one of"
  )
})

test_that("AgentSpec accepts MemorySpec objects and list payloads", {
  memory_spec <- MemorySpec$new(fields = list(memory_field(
    id = "episodic_trace",
    label = "Episodic trace",
    memory_type = "episodic",
    persistence = "jsonl_trace"
  )))

  spec <- AgentSpec$new(
    task = "Memory-aware design",
    agent_name = "memory-agent",
    memory_spec = memory_spec
  )

  expect_true(inherits(spec$memory_spec, "MemorySpec"))
  expect_equal(spec$design_summary()$memory_fields, 1L)

  list_spec <- AgentSpec$new(
    task = "List memory design",
    agent_name = "memory-list-agent",
    memory_spec = memory_spec$to_list()
  )

  expect_true(inherits(list_spec$memory_spec, "MemorySpec"))
  expect_equal(list_spec$memory_spec$get_field("episodic_trace")$persistence, "jsonl_trace")
})

