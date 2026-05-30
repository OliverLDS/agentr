# Table 3. Workflow Node Fields In agentr

Caption: Workflow node fields in `agentr`.

| Field | Meaning | Why it matters for scaffolding |
|---|---|---|
| `confidence` | Estimated confidence in the node definition or inferred step. | Helps identify uncertain workflow structure that may need clarification or review before approval. |
| `human_required` | Indicates whether the node requires explicit human participation or authorization. | Makes human gates visible so automation is not assumed where oversight is necessary. |
| `rule_spec` | Captures explicit rules, constraints, or decision criteria attached to the node. | Surfaces tacit procedural knowledge and makes approval logic or domain constraints inspectable. |
| `implementation_hint` | Stores a lightweight hint about how the node may later be implemented. | Supports handoff from scaffolding to implementation without collapsing design into code too early. |
| `complete` | Indicates whether the node has been sufficiently specified for the current scaffolding stage. | Helps track which parts of the workflow are mature enough for review, approval, or implementation planning. |
| `review_status` | Records the node’s current review state. | Makes review progression explicit and supports structured refinement instead of implicit judgment. |
| `review_notes` | Stores reviewer comments or concerns about the node. | Preserves critique and revision context so later edits remain accountable and understandable. |
| `review_confidence` | Records confidence in the review judgment rather than only in the node itself. | Distinguishes uncertain review outcomes from uncertain workflow content and helps prioritize follow-up. |
| `owner` | Records whether the node is currently owned by a human, script, LLM, agent, or external system. | Makes transitional human ownership explicit instead of hiding it behind generic automation claims. |
| `automation_status` | Describes the node’s current automation maturity. | Helps reviewers distinguish manual, human-in-the-loop, assisted, agent-owned, and validated autonomous steps. |
| `knowledge_refs` | Links the node to approved or proposed knowledge items. | Connects procedural steps to the domain knowledge or rules that justify them. |
| `subworkflow_ref` | Points to a lower-level workflow associated with the node. | Enables hierarchical review of high-level workflow steps without flattening every detail into one graph. |
| `input_schema` | Describes the expected input shape for the node. | Supports interface review and implementation handoff before runtime code exists. |
| `output_schema` | Describes the expected output shape for the node. | Makes downstream dependencies and JSON handoff expectations inspectable. |
| `nested_workflow` | Stores an optional embedded lower-level workflow. | Allows review tools to drill from a high-level node into a local detailed workflow chart. |
