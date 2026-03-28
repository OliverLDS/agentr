#' Load a JSON file
#'
#' @param path Path to a JSON file.
#' @param simplifyVector Passed to [jsonlite::fromJSON()].
#'
#' @return Parsed JSON content.
#' @export
load_json_file <- function(path, simplifyVector = TRUE) {
  jsonlite::fromJSON(path, simplifyVector = simplifyVector)
}

#' Load a YAML file
#'
#' @param path Path to a YAML file.
#'
#' @return Parsed YAML content.
#' @export
load_yaml_file <- function(path) {
  yaml::read_yaml(path)
}
