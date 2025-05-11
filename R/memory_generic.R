create_memory <- function() {
  list()
}

update_memory <- function(memory, key, value) {
  memory[[key]] <- value
  return(memory)
}