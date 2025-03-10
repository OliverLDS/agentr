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
