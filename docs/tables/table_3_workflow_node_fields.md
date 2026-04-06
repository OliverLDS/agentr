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
