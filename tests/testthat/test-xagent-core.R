test_that("init_mind_state creates expected default structure", {
  state <- init_mind_state()

  expect_type(state, "list")
  expect_named(state, c(
    "identity", "personality", "tone_guideline", "knowledge", "beliefs",
    "values", "emotion_state", "goals", "history", "current_context",
    "tool_config", "timezone"
  ))
  expect_equal(state$timezone, "Asia/Singapore")
})

test_that("compose_prompt_plain includes all parts", {
  out <- compose_prompt_plain(
    name = "Zelina",
    identity = "a crypto researcher",
    personality = "bold and sharp",
    tone_guideline = "professional",
    chat_history = "User: Hi\nZelina: Hello"
  )
  expect_true(grepl("Zelina", out))
  expect_true(grepl("crypto researcher", out))
  expect_true(grepl("Below is your previous chatting", out))
})
