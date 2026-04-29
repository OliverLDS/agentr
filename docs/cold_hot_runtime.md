# Cold vs Hot Runtime

`agentr` is a scaffolding and specification package first. It is not a full execution engine.

That matters because many R-user agents will run in a cold-start orchestration pattern rather than as a permanently live process.

## Cold-Start Orchestrated Runtime

Typical pattern:

```text
zsh orchestrator
-> Rscript loads AgentSpec / AgentState from .rds
-> refreshes environment data
-> performs one step
-> saves revised state to .rds
-> exits
```

This is a natural fit for many R workflows:

- cron jobs
- shell orchestration
- scheduled report pipelines
- data refreshers
- single-step decision support scripts

In this pattern, the agent does not need to stay alive in memory between steps.

## Hot Runtime

Hot runtime means a live object persists during the session:

- a long interactive R session
- a Shiny app
- a daemon-like process
- a notebook or REPL that keeps mutating state

Here, an R6 object can remain alive and accumulate state without repeated reload-save cycles.

## Why R6 Still Makes Sense

Even when deployment is cold-start oriented, R6 remains useful because it provides:

- validated design objects
- explicit methods
- persistence boundaries
- inspectable state containers
- a forward path to hotter runtimes if the agent later evolves

So the package keeps R6 for design quality and future extensibility, not because every agent is assumed to be a long-lived in-memory runtime.

## What Directly Shapes Behavior

Operational specs:

- `WorkflowSpec`
- `KnowledgeSpec`
- `StateSpec`
- `InterfaceSpec`

Diagnostic or design specs:

- `SubsystemSpec`
- autonomy labels
- ownership labels
- capability-gap labels

That separation keeps the package honest about what is actually behavior-shaping versus what is mainly explanatory or design-oriented.

