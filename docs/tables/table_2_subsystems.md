# Table 2. Subsystems In agentr And Their Intended Roles

Caption: Subsystems in `agentr` and their intended roles.

| Subsystem | Full name | Conceptual role | Typical need in a task |
|---|---|---|---|
| `RWM` | Reasoning & World Model | Supports reasoning, planning, inference, causal assumptions, and internal world-state interpretation, including cognitive or affective interpretation when needed. | Needed when the task requires strategy choice, model-based judgment, persistent reasoning context, or structured internal assumptions. |
| `PG` | Perception & Grounding | Handles data ingestion, artifact interpretation, schema understanding, source grounding, and mapping symbols or claims to data or environment. | Needed when the task must interpret data, ground text or claims in evidence, or understand external artifacts before reasoning or action. |
| `AE` | Action Execution | Carries out concrete task steps and operational actions in the workflow. | Needed in most tasks that involve producing outputs, transforming data, or executing workflow steps. |
| `IAC` | Inter-Agent Communication | Manages message passing, coordination, task handoff, and protocol structure among multiple agents. | Needed when the design truly involves multi-agent coordination rather than only human review or ordinary system interfaces. |
| `LA` | Learning & Adaptation | Incorporates feedback, reflection-to-rule conversion, policy updates, and adaptive improvement across iterations. | Needed when the task benefits from performance review, feedback loops, or gradual improvement of rules, prompts, or policies. |
