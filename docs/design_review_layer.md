# Design Review Layer

`agentr` uses the review layer to help humans inspect agent-design artifacts before they are approved or implemented. The review layer is deliberately not an execution environment.

## Why It Exists

Agent designs combine several artifact types:

- workflow nodes, edges, gates, ownership, and implementation hints;
- memory schema for context, semantic, episodic, and procedural memory;
- narrative knowledge items, rules, exceptions, and heuristics;
- graph-shaped knowledge as nodes and typed relationships;
- proposal states that show what is approved, pending, rejected, or superseded.

Reviewing those artifacts only as R lists is possible but awkward. `DesignReviewSpec` packages the same objects into a portable inspection artifact with these sections:

- `workflow_graph`
- `memory_schema`
- `narrative_knowledge`
- `graph_knowledge`
- `proposal_states`
- `feedback_schema`

## Standalone HTML

Use:

```r
review <- build_design_review_data(agent_spec)
export_design_review_html(review, "agent_design_review.html")
```

The generated file is self-contained and does not require Shiny, Quarto, a web server, or remote CDN resources.

The page shows:

- an interactive workflow graph with wrapped node labels;
- a detail inspector populated by node and edge clicks;
- nested-workflow badges and local nested-workflow previews;
- a draggable boundary between the graph and supporting panels;
- horizontal scrolling when the workflow graph is wider than its panel;
- selectable default and subsystem-color themes;
- narrative knowledge and graph-shaped knowledge;
- memory, state, interface, and autonomy schema;
- a structured feedback panel.

Node ids remain internal graph keys and are shown in the detail inspector, not as visible graph labels. The default theme distinguishes human gates, deterministic automation, and external stochastic LLM steps. The subsystem theme colors nodes by `RWM`, `PG`, `AE`, `LA`, and `IAC` tags.

Supported graph layouts are `grid`, `layered`, `swimlane`, and `process`. Use `process` for workflows with branches or backward edges. Branch metadata such as `condition`, `branch_group`, and `mutually_exclusive` is preserved for inspection and visible routing.

## Structured Feedback

The browser keeps an in-page feedback list and can copy or download JSON like:

```json
{
  "feedback": [
    {
      "target": "memory_schema",
      "target_id": "current_task_context",
      "field": "memory.fields.current_task_context",
      "issue_type": "too_broad",
      "issue": "Memory field mixes lifecycle and task state.",
      "suggestion": "Split lifecycle_state and task_state.",
      "severity": "high",
      "status": "open"
    }
  ]
}
```

Back in R:

```r
feedback <- parse_design_feedback_json("feedback.json")
validate_design_feedback(feedback, review_spec = review)
preview_design_feedback(scaffolder, feedback)
apply_design_feedback(scaffolder, feedback)
```

`preview_design_feedback()` is non-mutating. `apply_design_feedback()` routes feedback through existing scaffolder review/discussion mechanisms and stores structured feedback metadata. It does not execute workflow nodes.

## Boundary

The review layer may render artifacts and collect structured feedback. It must not call LLM providers, run R workflow steps, call external APIs, place orders, send messages, or directly mutate saved spec files from JavaScript. All feedback returns to R as data and passes R-side validation before it affects approved design artifacts.
