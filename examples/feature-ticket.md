# Example Feature Ticket

## Phase 1 - Core Parser

Build the first minimal parser.

<!-- codex:model=gpt-5.4-mini -->
<!-- codex:verify=bash tests/core-parser.sh -->

### Requirements

- Read local input files.
- Return structured output.
- Add focused tests.

## Phase 2 - Report Writer

Generate a JSON and Markdown report from parser output.

<!-- codex:read=examples/reporting-notes.md -->
<!-- codex:verify=bash tests/report-writer.sh -->

### Requirements

- Keep reports deterministic.
- Preserve existing behavior.

## Phase 3 - Dashboard Widget

Add a small dashboard widget that surfaces the latest report.

<!-- codex:verify=bash tests/dashboard-widget.sh -->

### Requirements

- Keep the UI scoped.
- Do not redesign the application.
