#' @keywords internal
new_prompt_contract <- function(input_type, target_role, expected_output) {
  list(
    input_type = input_type,
    target_role = target_role,
    expected_output = expected_output
  )
}

#' @keywords internal
.prompt_contract_payload <- function(contract, payload) {
  c(
    list(
      contract = contract
    ),
    payload
  )
}

#' @keywords internal
.prompt_json <- function(x) {
  jsonlite::toJSON(
    x,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )
}
