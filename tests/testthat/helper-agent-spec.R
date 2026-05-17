.test_complete_agent_spec <- function() {
  knowledge_spec <- KnowledgeSpec$new(items = list(
    list(
      id = "ki_yoy_macro_001",
      type = "heuristic",
      raw_statement = "For noisy monthly macro data, YoY is usually better than MoM.",
      normalized_statement = "For noisy monthly macro indicators, YoY is often more suitable than MoM for medium-term interpretation.",
      domain = "macro_analysis",
      conditions = c("monthly macro data", "medium-term trend interpretation"),
      exceptions = c("short-term shock timing"),
      confidence = "medium",
      review = list(status = "approved")
    )
  ))

  memory_spec <- MemorySpec$new(fields = list(
    memory_field(
      id = "current_task_context",
      label = "Current task context",
      memory_type = "context",
      description = "Current dataset, selected paragraph, and active analysis state.",
      schema = list(fields = c("current_dataset", "active_paragraph", "task_state")),
      persistence = "session",
      update_policy = list(updated_by = "scaffolder")
    ),
    memory_field(
      id = "approved_macro_concepts",
      label = "Approved macro concepts",
      memory_type = "semantic",
      description = "Reviewed macro-analysis concepts and charting heuristics.",
      schema = list(fields = c("term", "definition", "source")),
      persistence = "cold_start_rds",
      review = list(status = "approved")
    ),
    memory_field(
      id = "human_chart_decisions",
      label = "Human chart decisions",
      memory_type = "episodic",
      description = "Past human decisions about chart interpretation.",
      schema = list(fields = c("trace_id", "decision", "rationale", "outcome")),
      persistence = "jsonl_trace"
    ),
    memory_field(
      id = "paper_reading_workflow",
      label = "Paper reading workflow",
      memory_type = "procedural",
      description = "Reusable procedure for reading papers and extracting schema fields.",
      schema = list(workflow_ref = "workflow:paper_reading"),
      persistence = "cold_start_rds"
    )
  ))

  workflow <- new_workflow_spec(
    nodes = rbind(
      workflow_node(
        "node_refresh",
        "Refresh macro data",
        owner = "script",
        automation_status = "rule_assisted",
        knowledge_refs = character()
      ),
      workflow_node(
        "node_interpret",
        "Interpret macro chart",
        owner = "human",
        automation_status = "human_in_loop",
        human_owned_reason = "Human still judges whether the chart pattern is economically meaningful.",
        target_automation_status = "llm_assisted",
        trace_required = TRUE,
        knowledge_refs = c("ki_yoy_macro_001")
      )
    ),
    edges = workflow_edge("node_refresh", "node_interpret"),
    task = "Macro analysis fixture"
  )

  AgentSpec$new(
    task = "Macro analysis fixture",
    agent_name = "macro-fixture-agent",
    summary = "Complete fixture for review and persistence tests.",
    subsystems = SubsystemSpec$new(
      rwm = RWMConfig$new(cognitive = CognitiveConfig$new()),
      pg = PGConfig$new(),
      ae = AEConfig$new(),
      la = LAConfig$new()
    ),
    workflow = workflow,
    knowledge_spec = knowledge_spec,
    memory_spec = memory_spec,
    state_spec = list(
      lifecycle_state = list(
        allowed_values = c("idle", "refreshing_data", "interpreting", "awaiting_review"),
        persistent = TRUE
      ),
      task_state = list(
        fields = c("current_dataset", "latest_chart_path", "last_human_decision"),
        persistent = TRUE
      )
    ),
    interface_spec = list(
      files = list(
        inputs = c("data/macro/latest.csv"),
        outputs = c("reports/macro_summary.md")
      ),
      tools = list(
        r_packages = c("readr", "ggplot2")
      )
    ),
    autonomy_spec = list(
      default_stage = "human_in_loop",
      human_required_for = c("publish_report", "change_chart_rule")
    ),
    autonomy_stage = "human_in_loop",
    implementation_targets = list(
      primary_language = "R",
      runtime_pattern = "cold_start_orchestrated"
    ),
    metadata = list(
      runtime_pattern = "cold_start_orchestrated",
      node_subsystems = list(
        node_refresh = c("pg", "ae"),
        node_interpret = c("rwm", "pg", "la")
      )
    )
  )
}
