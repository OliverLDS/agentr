test_that("knowledge message parsing, preview, and apply are constrained", {
  state <- KnowledgeProposalState$new()
  json_text <- jsonlite::toJSON(
    list(
      actions = list(
        list(
          method = "propose_knowledge",
          args = list(
            id = "ki_001",
            raw_statement = "For macro charts, YoY is usually better than MoM because monthly data is noisy.",
            type = "heuristic",
            normalized_statement = "For noisy monthly macro indicators, YoY is often more suitable than MoM for medium-term interpretation.",
            conditions = list("monthly macro data"),
            exceptions = list("short-term shock timing"),
            confidence = "medium"
          )
        )
      )
    ),
    auto_unbox = TRUE
  )

  parsed <- parse_knowledge_message(json_text)
  expect_equal(parsed$actions[[1]]$method, "propose_knowledge")

  preview <- preview_knowledge_message(state, json_text)
  expect_equal(preview$proposal_count, 0L)
  expect_equal(length(state$proposals), 0L)

  state <- apply_knowledge_message(state, json_text)
  expect_equal(length(state$proposals), 1L)

  expect_error(
    parse_knowledge_message(list(actions = list(list(method = "run_code", args = list(code = "1+1"))))),
    "Unsupported knowledge action"
  )
})

