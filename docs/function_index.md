# Function Index

## Core R6 Classes

| Object | Purpose |
| --- | --- |
| `CognitiveState` | Minimal cognitive state container with update hooks |
| `AffectiveState` | Affective layer with inertia-aware updates |
| `AgentCore` | Minimal agent container for cognition, affect, and scaffolding |
| `Scaffolder` | Human-in-the-loop workflow elicitation interface |

## Workflow Helpers

| Function | Purpose |
| --- | --- |
| `workflow_node()` | Create a workflow node record |
| `workflow_edge()` | Create a workflow edge record |
| `new_workflow_spec()` | Build a workflow specification object |
| `validate_workflow_spec()` | Validate workflow structure |

## Affective Utilities

| Function | Purpose |
| --- | --- |
| `default_emotion_state()` | Create a default affective state |
| `define_random_emotion_state()` | Create a randomized affective state |
| `decay_emotion_state()` | Apply time-based decay |
| `combine_emotions()` | Combine affective dimensions |
| `compute_blended_emotions()` | Derive blended affective states |
| `describe_emotional_state()` | Summarize current affective state |

## Terminal Helpers

| Function | Purpose |
| --- | --- |
| `render_markdown_terminal()` | Render light markdown styling in terminals |
| `terminal_scaffold_input()` | Prompt for user input during scaffolding |
| `terminal_ask_node_complete()` | Ask whether a workflow node is complete |
| `terminal_ask_workflow_changes()` | Ask whether nodes should be added or removed |
| `terminal_ask_node_rule()` | Ask for a node-specific rule |

## Persistence and Serialization

| Function | Purpose |
| --- | --- |
| `save_agent()` | Save an `agentr` core object |
| `load_agent()` | Load an `agentr` core object |
| `backup_agent()` | Save a timestamped backup |
| `load_json_file()` | Load JSON files |
| `load_yaml_file()` | Load YAML files |
| `inferencer_available()` | Detect optional `inferencer` availability |
| `inferencer_integration()` | Build optional integration metadata |
