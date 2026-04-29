test_that("KnowledgeProposal and KnowledgeProposalState manage lifecycle", {
  item <- list(
    id = "ki_gold_real_yields_001",
    type = "causal_relation",
    raw_statement = "Gold often falls when real yields rise.",
    normalized_statement = "In normal market regimes, rising real yields tend to pressure gold prices.",
    domain = "macro_trading",
    structure = list(cause = "real_yields", effect = "gold_price", direction = "negative"),
    conditions = c("normal market regime"),
    exceptions = c("safe-haven demand"),
    confidence = "medium",
    review = list(status = "pending")
  )

  proposal <- KnowledgeProposal$new(item = item)
  expect_true(inherits(proposal, "KnowledgeProposal"))
  expect_equal(proposal$status, "pending")

  proposal$discuss("Add a USD caveat.")
  expect_equal(proposal$status, "under_discussion")

  state <- KnowledgeProposalState$new()
  state$add_proposal(proposal)
  state$discuss_proposal(proposal$id, "Need one more caveat.")
  approved <- state$approve_proposal(proposal$id)
  expect_true(inherits(approved, "KnowledgeProposal"))
  expect_equal(approved$status, "approved")
  expect_equal(length(state$approved_spec()$items), 1L)
  expect_equal(state$approved_spec()$get_item("ki_gold_real_yields_001")$review$status, "approved")

  proposal_2 <- KnowledgeProposal$new(item = modifyList(item, list(id = "ki_other_001")))
  state$add_proposal(proposal_2)
  rejected <- state$reject_proposal(proposal_2$id, note = "Too vague.")
  expect_equal(rejected$status, "rejected")
  expect_true(is.null(state$approved_spec()$items[["ki_other_001"]]))
})

