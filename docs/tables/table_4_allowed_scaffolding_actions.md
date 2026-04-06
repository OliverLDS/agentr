# Table 4. Allowed Scaffolding Actions In The Constrained LLM Bridge

Caption: Allowed scaffolding actions in the constrained LLM bridge.

| Action | Purpose | Typical use in refinement |
|---|---|---|
| `evaluate_task` | Produces an initial task assessment and scaffolding context. | Used at the start of a session to frame the task before decomposition or review. |
| `discuss_task` | Records free-form discussion about task intent, scope, or constraints. | Used when human or model feedback clarifies goals before structural changes are made. |
| `decompose_task` | Proposes or updates workflow nodes and edges for the task. | Used to construct or revise the candidate DAG during early or mid-stage refinement. |
| `review_workflow` | Captures workflow-level review judgments and concerns. | Used when assessing the adequacy, realism, or completeness of the workflow as a whole. |
| `review_node` | Captures review judgments for an individual workflow node. | Used when a specific node needs targeted critique, clarification, or approval. |
| `edit_workflow` | Applies explicit structural edits to nodes or edges. | Used when refinement requires concrete modifications rather than discussion alone. |
| `ask_human_complete` | Requests human confirmation that a node or workflow is sufficiently complete. | Used at approval checkpoints when model confidence is not enough to close review. |
| `ask_human_changes` | Requests human guidance about needed revisions. | Used when workflow or node structure appears inadequate but the required fix is not fully specified. |
| `ask_human_rule` | Requests human articulation of a governing rule or constraint. | Used when tacit procedural knowledge must be made explicit for a node or transition. |
| `apply_human_feedback` | Incorporates human-provided guidance into scaffolder state. | Used after human review to update workflow structure, rules, or completion status. |
