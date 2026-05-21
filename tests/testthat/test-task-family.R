test_that("task-family helpers create root workflow with child task nodes", {
  child <- child_task_node(
    id = "task_blog",
    label = "Write blog article",
    subworkflow_ref = "specs/workflows/blog.rds",
    input_schema = list(type = "object", required = c("arxiv_ids")),
    output_schema = list(type = "object", required = c("article_md")),
    owner = "human",
    automation_status = "human_in_loop"
  )

  workflow <- new_task_family_workflow(
    id = "family_research_publication",
    label = "Research publication maintenance",
    objective = "Coordinate related research-publication tasks.",
    nodes = child,
    shared_inputs = c("arxiv_ids"),
    shared_review_concerns = c("duplicate coverage"),
    task_tags = list(task_blog = c("publication", "blog"))
  )

  expect_s3_class(workflow, "agentr_workflow_spec")
  expect_equal(workflow$task, "Coordinate related research-publication tasks.")
  expect_equal(nrow(workflow$nodes), 1L)
  expect_equal(nrow(workflow$edges), 0L)
  expect_equal(workflow$metadata$task_family$id, "family_research_publication")
  expect_equal(workflow$metadata$task_family$child_tasks, "task_blog")
  expect_equal(workflow$metadata$task_family$task_tags$task_blog, c("publication", "blog"))
  expect_equal(workflow$nodes$input_schema[[1]]$required, "arxiv_ids")
})

test_that("add_child_task_node updates task-family metadata", {
  workflow <- new_task_family_workflow(
    id = "family",
    label = "Family",
    objective = "Coordinate child tasks."
  )
  workflow <- add_child_task_node(
    workflow,
    child_task_node("task_a", "Task A"),
    tags = c("first")
  )
  workflow <- add_child_task_node(
    workflow,
    child_task_node("task_b", "Task B"),
    tags = c("second")
  )

  expect_equal(workflow$metadata$task_family$child_tasks, c("task_a", "task_b"))
  expect_equal(workflow$metadata$task_family$task_tags$task_b, "second")
  expect_error(
    add_child_task_node(workflow, child_task_node("task_b", "Duplicate")),
    "already contains"
  )
})

test_that("task_family_metadata requires named task tags", {
  expect_error(
    task_family_metadata(
      id = "family",
      label = "Family",
      objective = "Coordinate child tasks.",
      task_tags = list(c("untagged"))
    ),
    "named list"
  )
})
