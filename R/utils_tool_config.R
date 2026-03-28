#' Check whether `inferencer` is available
#'
#' @return Logical scalar.
#' @export
inferencer_available <- function() {
  nzchar(system.file(package = "inferencer"))
}

#' Build optional integration metadata for `inferencer`
#'
#' Returns a lightweight descriptor rather than a duplicated provider client.
#'
#' @param profile Optional integration profile name.
#' @param prompt_template Optional prompt template identifier.
#'
#' @return Named list.
#' @export
inferencer_integration <- function(profile = NULL, prompt_template = NULL) {
  list(
    package = "inferencer",
    available = inferencer_available(),
    profile = profile,
    prompt_template = prompt_template
  )
}
