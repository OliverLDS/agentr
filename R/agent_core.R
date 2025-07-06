#' XAgent: A Modular AI Agent Class
#'
#' The `XAgent` class defines a flexible, modular AI agent using R6 that can:
#' 
#' - Maintain and update internal mental states (`mind_state`)
#' - Interact with humans via Telegram, local chat, or email
#' - Query LLMs like Groq and Gemini
#' - Maintain emotion and chat history
#' - Compose prompts and FSM-based responses
#' 
#' @section Fields:
#' - `name`: The name of the agent
#' - `mind_state`: The agent's internal state, including emotion, history, configuration
#' 
#' @section Methods:
#' - `initialize(name, mind_state)`: Initialize agent
#' - `run()`: Default run loop; can be overridden
#' - `get_state()`, `set_state(state)`: Access or change FSM state
#' - `log(msg)`, `get_logs()`: Logging utilities
#' - `add_chat_message(role, msg, channel)`, `get_chats()`: Chat memory
#' - `sync_TG_chats()`, `send_text_TG(txt)`, `send_image_TG(...)`: Telegram IO
#' - `send_email(to, subject, body, ...)`: Email output
#' - `sync_local_user_input()`, `send_text_local(txt)`, `popout_local(...)`: Local messaging
#' - `query_groq(prompt)`, `query_gemini(prompt)`: Query LLMs
#' - `compose_prompt_plain()`: Build prompt from memory
#' - `randomize_emotion()`, `decay_emotion()`, `describe_emotion()`: Manage emotion state
#' - `set_config(key)`, `get_config(key)`: Manage tool configs
#'
#' @format An R6 class object.
#' @export
XAgent <- R6::R6Class("XAgent",
  public = list(
    name = NULL,
    mind_state  = NULL,

    initialize = function(name = "agent", mind_state = NULL) {
      self$name <- name
      self$mind_state <- init_mind_state(mind_state)
      self$log(sprintf("Agent %s initialized.", self$name))
    },
    
    # FSM
    
    get_state = function() self$mind_state$current_context$state,
    set_state = function(state) {
      old <- self$mind_state$current_context$state
      if (!identical(old, state)) {
        self$mind_state$current_context$state <- state
        self$log(paste("State changed from", old, "to", state))
      }
    },
    
    # action logging
    
    log = function(msg) {
      df_log_entry <- data.frame(time = convert_time_to_tz(Sys.time(), tz = self$mind_state$timezone), msg = msg)
      new_logs <- rbind(df_log_entry, self$mind_state$history$logs)
      self$mind_state$history$logs <- new_logs[order(new_logs$time, decreasing = TRUE), ]
    },
    get_logs = function() self$mind_state$history$logs,

    # workflow should be overridden by other child agents
    
    run = function() {
      self$tg_check_and_reply()
      # self$local_check_and_reply()
    },
    
    tg_check_and_reply = function() {
      if(self$sync_TG_chats()) {
        self$send_text_TG(self$query_groq(self$compose_prompt_plain()))
      }
    },
    
    # mind_state

    update_mind_state = function(path, value) {
      self$log(sprintf("mind state updated: %s", paste(path, collapse = "$")))
      self$mind_state <- set_nested_path(self$mind_state, path, value)
    },
    
    # About interactions with human, some possible methods
    # handle_user_input = function(text), something human's NLP will change agent's 
    # summarize_chat = function(), something to summerize long term chatting history to a hidden summary so a markov model is feasible
    # chatting
    
    add_chat_message = function(role, msg, channel = "internal") {
      df_chat_entry <- data.frame(time = convert_time_to_tz(Sys.time(), tz = self$mind_state$timezone), 
        role = role, msg = msg, channel = channel)
      new_chats <- rbind(df_chat_entry, self$mind_state$history$chats)
      self$mind_state$history$chats <- new_chats[order(new_chats$time, decreasing = TRUE), ]
    },
    get_chats = function() self$mind_state$history$chats,
    
    # get configs
    
    set_config = function(key) {
      self$mind_state$tool_config[[key]] <- tool_set_config(key)
      self$log(sprintf("Tool config for '%s' set.", key))
    },
    get_config = function(key) self$mind_state$tool_config[[key]],
    
    # conversation_TG, which is necessary for all the agents.
    
    send_text_TG = function(txt, ...) {
      send_text_TG(txt, config = self$mind_state$tool_config$tg, ...)
      self$add_chat_message(self$name, txt, channel = "TG")
    },
    send_image_TG = function(image_path, caption_text, ...) {
      send_image_TG(image_path, caption_text, config = self$mind_state$tool_config$tg, ...)
      self$add_chat_message(self$name, sprintf("%s | %s", caption_text, image_path), channel = "TG")
    },
    sync_TG_chats = function() {
      old_update_ids <- self$mind_state$history$TG_chat_ids
      old_chats <- self$mind_state$history$chats
      res <- sync_TG_chats(old_update_ids = old_update_ids, config = self$mind_state$tool_config$tg)
      if (res$has_new) {
        self$mind_state$history$TG_chat_ids <- unique(c(old_update_ids, res$new_ids))
        res$df$time <- convert_time_to_tz(res$df$time, tz = self$mind_state$timezone)
        new_chats <- rbind(old_chats, res$df[, !(names(res$df) %in% "update_id")])
        self$mind_state$history$chats <- new_chats[order(new_chats$time, decreasing = TRUE), ]
      }
      return(res$has_new)
    },
    
    # conversation_email,
    
    send_email = function(to, subject, body, ...) {
      send_email(input = list(to = to, subject =subject, body = body), config = self$mind_state$tool_config$email, ...)
      self$log(sprintf("Send an email titled %s to %s.", subject, to))
    },
    
    # conversation_local,
    
    initial_chat_local = function() {
      file.create(self$mind_state$tool_config$localchat$chat_file)
      invisible(NULL)
    },
    popout_local = function(...) popout_local(self$mind_state$tool_config$localchat, ...),
    send_text_local = function(txt) {
      send_text_local(txt, self$name, self$mind_state$tool_config$localchat$chat_file)
      self$add_chat_message(self$name, txt, channel = "internal")
    },
    sync_local_user_input = function() {
      res <- sync_local_user_input(self$mind_state$tool_config$localchat$chat_file)
      if (res$has_new) {
        old_chats <- self$mind_state$history$chats
        res$df$time <- convert_time_to_tz(res$df$time, tz = self$mind_state$timezone)
        new_chats <- rbind(old_chats, res$df)
        self$mind_state$history$chats <- new_chats[order(new_chats$time, decreasing = TRUE), ]
      }
      return(res$has_new)
    },
    local_check_and_reply = function() {
      if(self$sync_local_user_input()) {
        # system("pkill -x TextMate") # it is better to be rolled down by user
        self$send_text_local(self$query_groq(self$compose_prompt_plain()))
        self$popout_local()
      }
    },
    
    # llms
    
    query_groq = function(prompt, ...) query_groq(prompt, config = self$mind_state$tool_config$groq, ...),
    query_gemini = function(prompt, ...) query_gemini(prompt, config = self$mind_state$tool_config$gemini, ...),
    
    # prompt
    
    compose_prompt_plain = function() {
      chats <- self$mind_state$history$chats
      if ("channel" %in% names(chats)) {
        chats$channel <- NULL
      }
      compose_prompt_plain(self$name, self$mind_state$identity, 
        self$mind_state$personality, self$mind_state$tone_guideline, 
        jsonlite::toJSON(chats, auto_unbox = TRUE, pretty = FALSE))
    },
    
    # emotion functions
    
    randomize_emotion = function(...) {
      self$mind_state$emotion_state <- define_random_emotion_state(...)
      self$log("Emotion state randomized.")
    },
    decay_emotion = function(...) {
      self$mind_state$emotion_state <- decay_emotion_state(self$mind_state$emotion_state, ...)
      self$log("Emotion state decayed.")
    },
    describe_emotion = function(...) describe_emotional_state(self$mind_state$emotion_state, ...)
  )
)

# name <- 'Xiaowei'
# mind_state <- list(
#   identity = "a gentle and poetic AI girl who often reflects on the world softly and emotionally.",
#   personality = "warm, introspective, curious about people, society, and technology.",
#   tone_guideline = "Speak with a delicate emotional tone, and always include a subtle thought or feeling."
# )
# agent <- XAgent$new(name, mind_state)
# agent$mind_state$timezone <- "Asia/Shanghai"
# agent$set_config('tg')
# agent$set_config('groq')
# agent$mind_state$history$TG_chat_ids <- as.numeric(664836500:664836510)
# agent$sync_TG_chats()
# save_agent(agent, './xiaowei.rds')
# 
# agent <- load_agent('./xiaowei.rds')
# agent$run()
# agent$get_logs()
# agent$get_chats()
# save_agent(agent, './xiaowei.rds')

# name <- 'Zelina'
# mind_state <- list(
#   identity = "a no-nonsense crypto trader and former investment banker from Hong Kong.",
#   personality = "clear, smart, and slightly provocative.",
#   tone_guideline = "Use technical vocabulary when needed, but be practical. Prioritize clarity over fluff."
# )
# agent <- XAgent$new(name, mind_state)
# agent$mind_state$timezone <- "Asia/Hong_Kong"
# agent$set_config('email')
# agent$set_config('gemini')
# 
# agent$send_email('olee7149@gmail.com', 'greet from Zelina', 'Good morning, Oliver')
# 
# agent$query_gemini('Please summarize the novel Great Expectations.')
# 
# agent$get_logs()

