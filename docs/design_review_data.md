# Design Review Data Bundle

`agentr` does not yet ship a JS/HTML review UI. Version `0.2.5.6` prepares the data contract that such a UI should consume and return.

The boundary object is `DesignReviewSpec`. It packages a current agent design into sections that a review page can render independently:

- `workflow_graph`: workflow nodes, edges, task text, and workflow metadata.
- `memory_schema`: context, semantic, episodic, and procedural memory fields.
- `narrative_knowledge`: curated plain-language knowledge items and vector references.
- `graph_knowledge`: graph-knowledge nodes and typed relations.
- `proposal_states`: optional workflow, knowledge, memory, graph, or custom proposal-state snapshots.
- `feedback_schema`: the structured feedback contract the UI should emit.

Build a bundle from a complete `AgentSpec`:

```r
review <- build_design_review_data(agent_spec)
bundle <- review$to_list()
```

The returned list is JSON-ready. A future review layer can render the bundle, collect comments, and return structured feedback rather than unstructured prose.

```json
{
  "target": "memory_schema",
  "field": "agent.memory.state",
  "issue": "state names are unclear",
  "suggestion": "separate lifecycle_state from task_state",
  "severity": "medium"
}
```

Use `design_feedback_item()` to create feedback in R, `validate_design_feedback()` to check it, and `parse_design_feedback_json()` to parse feedback returned from a browser or external tool.

This release intentionally stops at the data boundary. Rendering, browser event handling, and persistence of review sessions belong to the later JS/HTML review-layer work.
