Figure 6. Human--LLM scaffolding interaction loop.

The diagram shows the audit-oriented loop in which `build_scaffolder_prompt()` produces constrained context for a reasoning model, the model returns JSON actions, those actions are validated, and `apply_scaffolder_message()` updates workflow or proposal state. Human feedback methods such as `ask_human_rule`, `ask_human_changes`, and `apply_human_feedback` enter the same loop as explicit and auditable interventions.
