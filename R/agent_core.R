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
Agent <- R6::R6Class("Agent",
  public = list(
    user_name = NULL,
    name = NULL,
    timezone = NULL,
    tool_config = list(),
    mind_state = list(
      # Slow-changing attributes
      identity = NA_character_,
      personality = NA_character_,
      tone_guideline = NA_character_,
      values = list(risk_aversion = NA_real_, verbosity = NA_real_),
      # Fast-changing cognitive state
      emotion_state = default_emotion_state(),
      knowledge = list(),
      beliefs = list(),
      goals = list(),
      current_context = list(state = NA_character_),
      workflow_fsm = NA_character_,
      # Memory about the *user*
      memory_user_short = list(),
      memory_user_long = list(),
      # Conversation + internal trace
      history = list(
        logs = data.table::data.table(timestamp = as.POSIXct(character(0L)), msg = character(0L)), 
        chats = data.table::data.table(timestamp = as.POSIXct(character(0L)), role = character(0L), msg = character(0L), type = character(0L), channel = character(0L)),
        TG_chat_ids = integer(0))
    ),
    
    initialize = function(user_name = "your name", name = "agent’s name", tz = "Asia/Hong_Kong", mind_state = NULL) {
      self$user_name <- user_name
      self$name <- name
      self$timezone <- tz
      if (!is.null(mind_state)) {
        for (k in names(mind_state)) {
          self$mind_state[[k]] <- mind_state[[k]]
        }
      }
      self$log(sprintf("Initialized agent '%s' for user '%s'[timezone: %s].", self$name, self$user_name, self$timezone))
      invisible(NULL)
    },
    
    #---- Time zone ----
    
    set_tz = function(tz) {
      old <- self$timezone
      if (!identical(old, tz)) {
        self$timezone <- tz
        self$log(sprintf("Timezone changed from %s to %s.", old, tz))
      }
      invisible(NULL)
    },
    get_tz = function(tz) {
      self$timezone
    },
    
    #---- Memory ----
    export_memory = function(path) {
      .safe_save_rds(self$mind_state, path)
      invisible(NULL)
    },
    import_memory = function(path) {
      self$mind_state <- .safe_read_rds(path)  
      self$log(sprintf("Memory state successfully imported from '%s'.", path))
      invisible(NULL)
    },
    
    #---- mind state i/o ----
    
    set_mind_state = function(key, new_value) {
      old_value <- self$mind_state[[key]]
      if (!identical(old_value, new_value)) {
        self$mind_state[[key]] <- new_value
        self$log(sprintf("State changed from %s to %s.", old_value, new_value))
      }
      invisible(NULL)
    },
    get_mind_state = function(key) {
      self$mind_state[[key]]
    },
    
    # action logging
    
    log = function(msg) {
      df_log_entry <- data.table::data.table(timestamp = .to_tz(Sys.time(), tz = self$get_tz()), msg = msg)
      self$mind_state$history$logs <- data.table::rbindlist(list(self$get_logs(), df_log_entry), fill = TRUE)
      invisible(NULL)
    },
    get_logs = function(recent_n = NULL, newest_first = FALSE) {
      logs <- self$mind_state$history$logs
      if (!is.null(recent_n)) logs <- tail(logs, recent_n)
      if (newest_first) data.table::setorder(logs, -timestamp)
      logs
    },

    # workflow should be overridden by other child agents
    
    run = function() {
      self$tg_check_and_reply()
      invisible(NULL)
    },
    
    tg_check_and_reply = function() {
      if(self$sync_TG_chats()) {
        self$send_text_TG(self$query_groq(self$compose_prompt_plain()))
      }
    },
    
    # chat loging
    add_chat_message = function(role, msg, type = "dialog", channel = "internal") {
      dt_chat_entry <- data.table::data.table(timestamp = .to_tz(Sys.time(), tz = self$get_tz()), 
        role = role, msg = msg, type = type, channel = channel)
      self$mind_state$history$chats <- data.table::rbindlist(list(self$get_chats(), dt_chat_entry), fill = TRUE)
      invisible(NULL)
    },
    get_chats = function(recent_n = NULL, newest_first = FALSE) {
      chats <- self$mind_state$history$chats
      if (!is.null(recent_n)) chats <- tail(chats, recent_n)
      if (newest_first) data.table::setorder(chats, -timestamp)
      chats
    },
    
    # get configs
    
    set_config = function(key, value = NULL) {
      if (is.null(value)) value <- .set_tool_config(key)
      self$tool_config[[key]] <- value
      self$log(sprintf("Tool config for '%s' set.", key))
      invisible(NULL)
    },
    get_config = function(key) {
      self$tool_config[[key]]
    },
    
    # conversation through Telegram
    
    send_TG_text_to_user= function(txt, ...) {
      send_text_TG(txt, config = self$get_config('tg'), ...)
      self$add_chat_message(self$name, txt, channel = "TG")
      invisible(NULL)
    },
    send_TG_image_to_user = function(image_path, caption_text, ...) {
      send_image_TG(image_path, caption_text, config = self$get_config('tg'), ...)
      self$add_chat_message(self$name, sprintf("%s | %s", caption_text, image_path), channel = "TG")
      invisible(NULL)
    },
    sync_TG_chats = function() { #----- we need to replace the TG chat name with self$user_name here -----
      old_update_ids <- self$mind_state$history$TG_chat_ids
      old_chats <- self$get_chats()
      res <- sync_TG_chats(old_update_ids = old_update_ids, config = self$get_config('tg'))
      if (res$has_new) {
        self$mind_state$history$TG_chat_ids <- unique(c(old_update_ids, res$new_ids))
        res$df$time <- convert_time_to_tz(res$df$time, tz = self$get_tz())
        new_chats <- rbind(old_chats, res$df[, !(names(res$df) %in% "update_id")])
        self$mind_state$history$chats <- new_chats[order(new_chats$time, decreasing = TRUE), ]
      }
      return(res$has_new)
    },
    
    # conversation through email
    
    send_email_to_user = function(to, subject, body, html = FALSE) {
      send_email(input = list(to = to, subject =subject, body = body), html = html, config = self$get_config('email'))
      self$log(sprintf("Send an email titled %s to %s.", subject, to))
    },
    
    # conversation through terminal
    
    send_msg_to_user_terminal = function(msg, type = 'dialog') {
      cat(self$name, ': ', .render_markdown_terminal(msg), "\n")
      self$add_chat_message(self$name, msg, type = type, channel = "internal")  
      invisible(NULL)
    },
    receive_msg_from_user_terminal = function(msg) {
      self$add_chat_message(self$user_name, msg, channel = "internal")
    },
    show_logs_terminal = function(recent_n = NULL) {
      dt <- self$get_logs(recent_n = recent_n)
      for (i in 1:nrow(dt)) cat(sprintf("%s: %s\n", .fmt_ts(dt[i, 1]), dt[i, 2]))
    },
    show_chats_terminal = function(recent_n = NULL, dialog_only = TRUE) {
      dt <- self$get_chats(recent_n = recent_n)
      if (dialog_only) dt <- dt[type == 'dialog', ]
      for (i in 1:nrow(dt)) cat(sprintf("%s | %s: %s\n\n", .fmt_ts(dt[i, 1]), dt[i, 2], dt[i, 3]))
    },
    
    # llms
    
    query_groq = function(prompt, ...) {
      query_groq(prompt, config = self$get_config('groq'), ...)
    },
    query_gemini = function(prompt, ...) {
      query_gemini(prompt, config = self$get_config('gemini'), ...)
    },
    
    # prompt templates
    # ---- prompt templates should be very enriched; data collecter should mainly be run in VM; a local data collecter downloaded/sync from VM ----
    
    render_prompt = function(template_file_name, args) {
      path <- system.file("prompts", paste0(template_file_name, '.txt'), package = "agentr")
      template <- readChar(path, file.info(path)$size, useBytes = TRUE)
      .render_prompt(template, args)
    },
    render_prompt_head = function() {
      self$render_prompt('head1', list(name = self$name, identity = self$mind_state$identity, personality = self$mind_state$personality, tone_guideline = self$mind_state$tone_guideline, user_name = self$user_name))
    },
    render_prompt_reply = function() {
      separted_chats <- .separate_chats(self$name, self$get_chats())
      if (separted_chats$unreplied_msg != '[]') {
        separted_chats$user_name <- self$user_name
        separted_chats$agent_name <- self$name
        return(self$render_prompt('reply1', separted_chats))
      } else {
        return(NA_character_)  
      }
    },
    
    # below need to be revised so we can separate historical and new chats
    compose_prompt_plain = function() {
      chats <- self$get_chats()
      if ("channel" %in% names(chats)) {
        chats$channel <- NULL
      }
      compose_prompt_plain(self$name, self$mind_state$identity, 
        self$mind_state$personality, self$mind_state$tone_guideline, 
        jsonlite::toJSON(chats, auto_unbox = TRUE, pretty = FALSE))
    },
    
    # emotion functions
    
    randomize_emotion = function(...) {
      self$set_mind_state('emotion_state', define_random_emotion_state(...))
      self$log("Emotion state randomized.")
      invisible(NULL)
    },
    decay_emotion = function(...) {
      self$mind_state$emotion_state <- decay_emotion_state(self$mind_state$emotion_state, ...)
      self$log("Emotion state decayed.")
      invisible(NULL)
    },
    describe_emotion = function(...) {
      describe_emotional_state(self$get_mind_state('emotion_state'), ...)
    }
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

