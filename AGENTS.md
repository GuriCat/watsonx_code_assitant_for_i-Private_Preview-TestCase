# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Build/Lint/Test Commands

There are no standard build/lint/test commands defined in `package.json`.  Build and execution are likely handled through the IBM i integrated development environment.

## Code Style Guidelines

- RPGLE code uses free-format style (indicated by `RPGI2A_FreeFormat.RPGLE`).
- Database files use `.PF` (physical file) and `.LF` (logical file) extensions.
- SQL is embedded within RPGLE using the `SQLRPGLE` extension.

## Non-Obvious Patterns

- The project uses a mix of traditional RPGLE (`RPGI2A.RPG`, `RPGI2ALR.RPGLE`, `RPGI2LE.RPGLE`) and SQLRPGLE (`DSPSVRSTSR.SQLRPGLE`).
- The `新しいプロジェクト/` directory contains a new project setup, potentially using different conventions.
- The `config/settings.json` file likely contains project-specific configuration settings.

## Mode-Specific Guidance

See the `.roo/rules-*` directories for mode-specific instructions.