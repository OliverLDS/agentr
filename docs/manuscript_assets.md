# Manuscript Assets

The `docs/manuscript/` directory contains a manuscript-oriented asset set
alongside the main package documentation.

## Purpose

These assets are intended to support:

- package concept explanations
- manuscript figures and tables
- slide or note reuse for architecture and workflow discussions

## Structure

- [manuscript/figures/index.md](manuscript/figures/index.md): figure inventory with source, render, and caption links
- [manuscript/tables/index.md](manuscript/tables/index.md): table inventory with Markdown and LaTeX links
- [conceptual_figures.md](conceptual_figures.md): narrative hub for the main conceptual figures

## Design intent

The manuscript assets are meant to stay conceptually aligned with the package surface while remaining separate from generated package documentation. `agentr` is framed here as the cognitive and human-interaction core for intelligent-agent scaffolding, not as the downstream execution layer.
