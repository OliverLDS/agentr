# Capability-Autonomy Landscape

`agentr` is built for transitional scaffolding, not only final autonomy.

One useful way to interpret agent evolution is with two axes:

- Y-axis: autonomy level
- X-axis: capability specialization or diversification

This framing matters because multi-agent coordination is not simply "the highest stage." It is a different trajectory that only some agents need.

## Example Landscape

Execution cluster:

- API data collectors
- RDS data refreshers
- report builders with fixed templates

Analytical cognition cluster:

- chart interpretation assistants
- model-selection assistants
- economic-analysis agents

Knowledge-curation cluster:

- heuristic proposal agents
- rule and exception proposal agents
- knowledge conflict-check agents

Adaptive cluster:

- feedback-driven report improvers
- self-tuning strategy evaluators
- reflection-to-rule conversion agents

Coordination cluster:

- multi-agent research pipelines
- role-specialized analysis teams
- distributed strategy agents

## Subsystem Interpretation

The corrected five-module meanings in `agentr` are:

- `RWM`: Reasoning & World Model
- `PG`: Perception & Grounding
- `AE`: Action Execution
- `LA`: Learning & Adaptation
- `IAC`: Inter-Agent Communication

These are design and diagnostic labels, not claims that every subsystem is already fully implemented as runtime code.

## Transitional Scaffolding View

Many R-user agents begin here:

```text
manual R workflow
-> scripted tool
-> human-in-the-loop scaffold
-> LLM-assisted agent
-> validated autonomous agent
```

The point of `agentr` is to make that path inspectable:

- which workflow nodes are still human-owned
- which traces are being collected
- which knowledge items are becoming reusable rules
- which capability gaps remain unautomated

That is more useful for many practitioners than pretending the agent is already fully autonomous from the start.

