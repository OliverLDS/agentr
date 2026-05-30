# KnowledgeSpec Lifecycle

`WorkflowSpec` alone is not enough for many R-user agents.

A workflow can say:

- ingest data
- interpret results
- draft output
- review before release

But it often does not capture the domain knowledge that makes those steps reliable:

- concepts the agent should use
- causal beliefs it should treat as plausible
- heuristics it should apply under normal conditions
- exceptions that should override the default rule
- evaluation criteria that distinguish a good output from a weak one

`KnowledgeSpec` is the package surface for that curated knowledge layer. It can hold narrative knowledge items, first-class graph knowledge, and future references to external vector knowledge.

## Why Workflow Alone Is Insufficient

Workflow captures procedural knowledge: what the agent does.

Knowledge captures epistemic and domain knowledge: what the agent knows, assumes, or treats as an exception while doing it.

In transitional scaffolding, humans still perform part of this reasoning. `agentr` helps move that judgment into reviewable artifacts rather than leaving it implicit.

## Knowledge Types

- `concept`
- `causal_relation`
- `rule`
- `exception`
- `heuristic`
- `evaluation_criterion`
- `domain_constraint`
- `style_preference`
- `risk_warning`

Knowledge can also be represented as graph relationships:

```text
ACT-R --is_a--> cognitive architecture
Soar --is_a--> cognitive architecture
BDI --has_component--> Belief
BDI --has_component--> Desire
BDI --has_component--> Intention
ReAct --implements_part_of--> observe-decide-act
ReAct --lacks_explicitly--> commitment mechanism
```

In `agentr`, `knowledge_graph_from_spec()` creates a projection graph from narrative knowledge items. A curated `agentr_knowledge_graph_spec` stores graph knowledge directly and can be embedded in `KnowledgeSpec`.

Graph knowledge has its own proposal lifecycle through `KnowledgeGraphProposal` and `KnowledgeGraphProposalState`. This makes graph extraction reviewable before graph relationships become active knowledge.

The constrained message helpers are:

- `build_knowledge_graph_extraction_prompt()`
- `build_knowledge_graph_revision_prompt()`
- `parse_knowledge_graph_message()`
- `preview_knowledge_graph_message()`
- `apply_knowledge_graph_message()`

## Curation Lifecycle

The important feature is not only storage. It is the curation path:

1. raw human statement
2. normalization into a structured candidate
3. scope, condition, and exception extraction
4. conflict or duplication check
5. human discussion and review
6. approval into active `KnowledgeSpec`

This keeps vague or redundant human knowledge from being treated as fully approved behavior too early.

## Proposal Lifecycle

Knowledge proposals move through:

- `pending`
- `under_discussion`
- `approved`
- `rejected`
- `superseded`

Approved items become part of the active `KnowledgeSpec`. Rejected or superseded items remain inspectable rather than disappearing silently.

## Conflict Checking

Conflict checking is intended to detect:

- duplication
- contradiction
- stronger or weaker restatements
- scope mismatch
- terminology mismatch
- exception-vs-rule relationships

The first implementation stores conflict reports as structured lists. That is enough to keep the review boundary explicit.

## Linking Knowledge To Workflow

Workflow nodes may carry `knowledge_refs`.

That link answers a practical question:

Which approved knowledge items should constrain or guide this node?

Examples:

- a macro-analysis node may reference a heuristic about using YoY transformations
- a business-writing node may reference style preferences and exception rules
- a trading-analysis node may reference a causal relation plus several regime exceptions

## R-User Examples

Data analysis:

- "For noisy monthly macro series, YoY is often better than MoM."
- "Do not use dual-axis charts unless the interpretive gain is explicit."

Business writing:

- "A LinkedIn post should present one defensible thesis, one caveat, and one discussion prompt."

Quantitative trading:

- "Rising real yields often pressure gold in normal regimes, but crisis safe-haven demand can dominate."

These are not only facts. They are practitioner knowledge candidates that need normalization, scope control, and human review before they guide an agent.

## Design Review Layer

Approved and proposed knowledge can be inspected through the standalone design review layer. `build_design_review_data()` includes narrative knowledge and graph knowledge sections, while `export_design_review_html()` renders them alongside workflow and memory schema.

Feedback exported from the browser remains structured data. It must pass `parse_design_feedback_json()` and `validate_design_feedback()` before it is routed back into scaffolding or proposal state.

For task-local editable artifacts, prefer `docs/knowledge_spec.yaml`. Use JSON for interchange and RDS for R-native persistence or cache artifacts. See [Spec Formats](spec_formats.md) and [Knowledge Graph Spec](knowledge_graph_spec.md).
