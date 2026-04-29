test_that("subsystem semantics use corrected meanings", {
  rwm_output <- paste(capture.output(RWMConfig$new()$print()), collapse = "\n")
  pg_output <- paste(capture.output(PGConfig$new()$print()), collapse = "\n")
  iac_output <- paste(capture.output(IACConfig$new(channels = "handoff")$print()), collapse = "\n")

  expect_true(grepl("Reasoning & World Model", rwm_output, fixed = TRUE))
  expect_true(grepl("Perception & Grounding", pg_output, fixed = TRUE))
  expect_true(grepl("Inter-Agent Communication", iac_output, fixed = TRUE))
  expect_false(grepl("Reflective Working Memory", rwm_output, fixed = TRUE))
  expect_false(grepl("Planning and Goal Management", pg_output, fixed = TRUE))

  scaffolder <- Scaffolder$new(agent = AgentCore$new())
  scaffolder$evaluate_task("Interpret source data and produce an action")
  prompt <- build_agent_design_prompt(scaffolder, format = "markdown")

  expect_true(grepl("Use RWM for reasoning, planning, inference, and world-model structure", prompt, fixed = TRUE))
  expect_true(grepl("Use PG for perception, grounding, source interpretation, and artifact understanding", prompt, fixed = TRUE))
  expect_false(grepl("Reflective Working Memory", prompt, fixed = TRUE))
  expect_false(grepl("Planning and Goal Management", prompt, fixed = TRUE))
})

