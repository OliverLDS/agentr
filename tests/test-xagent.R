library(testthat)

test_that("Memory functions work correctly", {
  mem <- create_memory()
  expect_equal(length(mem$messages), 0)

  mem <- add_message(mem, "user", "Hello, AI!")
  expect_equal(length(mem$messages), 1)
  expect_equal(mem$messages[[1]]$role, "user")
})

test_that("LlmConfig works as expected", {
  conf <- LlmConfig("FAKE_KEY", "openai")
  expect_equal(conf$provider, "openai")
  expect_equal(conf$model, "gpt-4-turbo")
})

test_that("Tools work correctly", {
  mem <- create_memory()
  result <- example_tool_uppercase(mem, "hello")
  expect_equal(result$output, "HELLO")

  result <- example_tool_terminate(mem)
  expect_equal(result$output, "Terminating flow.")
})

