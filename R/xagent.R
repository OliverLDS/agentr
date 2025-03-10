run_xagent <- function(memory, prompt, config, max_steps = 3L) {
  new_mem <- add_message(memory, "user", prompt)
  final_mem <- call_llm(new_mem, config)
  final_mem
}
