#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  render_task_previews.sh --root DIR [options]

Options:
  --root DIR
      Workspace root to scan. Defaults to the current working directory.

  --tasks-dir DIR
      Tasks directory relative to --root, or an absolute path. Default: tasks.

  --graph-layout NAME
      Workflow graph layout: grid, layered, swimlane, or process.
      Default: process.

  --edge-style NAME
      Workflow edge style: curved, straight, or orthogonal.
      Default: orthogonal.

  --node-color-theme NAME
      Node color theme: default or subsystems.
      Default: default.

  -h, --help
      Show this help.

Role:
  Re-render task-local review HTML files from editable YAML specs. The script
  loads workflow_spec.yaml plus optional memory_spec.yaml, knowledge_spec.yaml,
  and knowledge_graph_spec.yaml when present. It does not execute task code.
USAGE
}

ROOT="$(pwd)"
TASKS_DIR="tasks"
GRAPH_LAYOUT="process"
EDGE_STYLE="orthogonal"
NODE_COLOR_THEME="default"

while (($# > 0)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --root)
      [[ $# -ge 2 ]] || { print -u2 -- "Missing value for --root"; exit 1; }
      ROOT="$2"
      shift 2
      ;;
    --tasks-dir)
      [[ $# -ge 2 ]] || { print -u2 -- "Missing value for --tasks-dir"; exit 1; }
      TASKS_DIR="$2"
      shift 2
      ;;
    --graph-layout)
      [[ $# -ge 2 ]] || { print -u2 -- "Missing value for --graph-layout"; exit 1; }
      GRAPH_LAYOUT="$2"
      shift 2
      ;;
    --edge-style)
      [[ $# -ge 2 ]] || { print -u2 -- "Missing value for --edge-style"; exit 1; }
      EDGE_STYLE="$2"
      shift 2
      ;;
    --node-color-theme)
      [[ $# -ge 2 ]] || { print -u2 -- "Missing value for --node-color-theme"; exit 1; }
      NODE_COLOR_THEME="$2"
      shift 2
      ;;
    --*)
      print -u2 -- "Unknown option: $1"
      usage >&2
      exit 1
      ;;
    *)
      print -u2 -- "Unexpected positional argument: $1"
      usage >&2
      exit 1
      ;;
  esac
done

export LC_ALL=C
export LANG=C

R_BIN="${R_BIN:-Rscript}"

"$R_BIN" -e '
  suppressPackageStartupMessages(library(agentr))
  args <- commandArgs(trailingOnly = TRUE)
  out <- render_task_previews(
    root = args[[1]],
    tasks_dir = args[[2]],
    graph_layout = args[[3]],
    edge_style = args[[4]],
    node_color_theme = args[[5]]
  )
  cat(sprintf("Rendered %d preview HTML files.\n", nrow(out)))
' "$ROOT" "$TASKS_DIR" "$GRAPH_LAYOUT" "$EDGE_STYLE" "$NODE_COLOR_THEME"
