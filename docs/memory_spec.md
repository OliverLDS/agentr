# MemorySpec

`MemorySpec` is the first-class schema for agent memory in `agentr`.

It records what memory fields exist, what type of memory they represent, how they update, and whether they persist across cold-start runs. It is a design artifact, not an execution engine.

## Why MemorySpec Exists

`WorkflowSpec` describes what the agent does.

`KnowledgeSpec` describes curated knowledge, assumptions, rules, exceptions, and concepts.

`MemorySpec` describes what the agent remembers and how that memory is structured.

This matters for transitional scaffolding because early agent designs often depend on human-owned memory. A human may remember prior user preferences, paper-specific context, past decisions, or reusable procedures that are not yet formalized in code.

## Memory Types

`agentr` uses four memory types:

- `context`: current conversation, task, or session state.
- `semantic`: general facts, concepts, definitions, and domain knowledge.
- `episodic`: specific past events, interactions, traces, and decisions.
- `procedural`: reusable procedures, workflows, and methods.

Example mapping:

| Memory type | Example |
| --- | --- |
| `context` | The user is asking about terms from this paper paragraph. |
| `semantic` | ACT-R is a cognitive architecture. |
| `episodic` | Last week, the user asked about ReAct and tool-use agents. |
| `procedural` | A workflow for reading a paper, extracting schema fields, and writing an article. |

## Persistence Policies

Memory fields can use these persistence policies:

- `session`: valid only inside the current session.
- `cold_start_rds`: persisted as R-native state across cold-start runs.
- `jsonl_trace`: append-only trace storage, useful for episodic evidence.
- `external_store`: stored outside `agentr`, such as a database or vector store.
- `none`: explicitly non-persistent.

## Example

```r
memory_spec <- MemorySpec$new(fields = list(
  memory_field(
    id = "current_task_context",
    label = "Current task context",
    memory_type = "context",
    description = "Current paragraph and task state.",
    schema = list(fields = c("paper_id", "paragraph_id", "question")),
    persistence = "session"
  ),
  memory_field(
    id = "agent_concepts",
    label = "Agent concepts",
    memory_type = "semantic",
    description = "Approved concepts and definitions.",
    schema = list(fields = c("term", "definition", "source")),
    persistence = "cold_start_rds",
    review = list(status = "approved")
  ),
  memory_field(
    id = "user_interaction_history",
    label = "User interaction history",
    memory_type = "episodic",
    description = "Past user questions and agent responses.",
    schema = list(fields = c("timestamp", "question", "response_summary")),
    persistence = "jsonl_trace"
  ),
  memory_field(
    id = "paper_reading_method",
    label = "Paper reading method",
    memory_type = "procedural",
    description = "Reusable procedure for reading and summarizing papers.",
    schema = list(workflow_ref = "workflow:paper_reading"),
    persistence = "cold_start_rds"
  )
))
```

## Relationship To state_spec

`state_spec` remains supported for backward compatibility and lightweight designs.

Use `MemorySpec` when the memory schema should be inspected, reviewed, persisted, or shown in a future design-review layer. Use `state_spec` for simple loose state notes or legacy code that already stores state as plain lists.

## Relationship To KnowledgeSpec

`KnowledgeSpec` stores curated knowledge items and proposals.

`MemorySpec` stores the schema that says where knowledge-like information may live and how it should persist.

For example:

- a `KnowledgeSpec` item may say `ACT-R is a cognitive architecture`;
- a `MemorySpec` semantic field may say approved concept definitions are stored under `agent_concepts`;
- a future knowledge graph can represent `ACT-R --is_a--> cognitive architecture`.

