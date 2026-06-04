# Coding Assistant Node Script Construction Guide

This guide describes how a coding assistant should write one standardized
executable node script. It is intended to be reusable across packages, not only
for task folders managed with `agentr`.

For the package-level framing of coding-assistant scaffolding, see
`../../docs/coding_assistant_scaffolding.md`.

Use this guide when a package needs a node-style CLI script that can be called
by a task orchestrator, another package, or a human operator.

## Core Goal

Generate node scripts that are:

- single-purpose
- explicit about inputs and side effects
- easy to inspect and rerun
- stable in their machine-visible outputs
- consistent across packages

## Required Script Contract

Every executable node script should support `-h` and `--help`.

This applies to:

- `*.sh`
- `*.R`
- `*.py`
- other executable entrypoints used as node scripts

The help output should include:

- a short usage line
- required positional arguments
- supported flags
- a brief description of the node’s role
- major side effects when relevant

If a script is meant to be called only by another script, it still needs help
output. Hidden entrypoints are harder to maintain and review.

## Single-Purpose Rule

Each node script should do one conceptual step.

Examples:

- build a prompt
- validate a local file
- normalize an output artifact
- append one trace record
- call an external package node
- send a prompt through UI automation
- wait for output readiness
- copy output into a local file

Do not merge unrelated responsibilities into one node unless they are
inseparable from a review standpoint.

## Output Contract

Node outputs that are consumed by later steps should be JSON when practical.

Prefer JSON for:

- success or failure status
- file paths
- generated prompt text
- extracted metadata
- validation results
- externally produced structured data

Design the JSON response so later steps can inspect fields without parsing
free-form text.

Recommended pattern:

```json
{
  "success": true,
  "output_file": "cache/article.md",
  "error": null
}
```

If a node promises JSON fields, keep those field names stable across runs.
Changing output keys should be treated as an interface change, not a casual
implementation detail.

## Side Effects

If a node writes files, commits git changes, pushes to a remote, sends email,
drives browser UI, uses the clipboard, downloads files, launches a server, or
calls another package’s node, make that side effect obvious in:

- the help text
- the JSON output when relevant
- the calling spec or task docs

## External Node Calls

When a step already exists as an executable node in another package, prefer
calling that node instead of reimplementing the logic locally.

Examples of external node sources:

- `autogui` package scripts for browser or desktop interactions
- `litxr` package scripts for literature processing
- future local model packages for classification, scoring, or other services

This means a node implementation should resolve to one of two paths:

- call an existing external node script
- create the node locally in the current package

Do not define this boundary in terms of “UI-driven” versus “deterministic”
alone. The deciding factor is whether a reusable executable node already exists.

## External LLM Steps

External LLM steps are first-class workflow nodes, but they are not always local
node scripts.

When the semantic step is “the external LLM generates a response,” that concept
should usually appear in the workflow spec even if there is no local script that
implements the generation itself.

Local node scripts should therefore focus on the parts they actually own, such
as:

- building the prompt
- sending the prompt through a UI or API client
- waiting for response readiness
- retrieving the response
- validating or normalizing the result

Do not model an external LLM response-generation step as a human node unless a
real human review or approval happens there.

## Validation Checklist

Before considering a node script complete, check:

- `-h/--help` works
- required inputs are explicit
- side effects are visible
- JSON output is used when the node has machine-visible outputs
- output keys are stable
- the script does one conceptual step
- the external package boundary is explicit when the node delegates work
