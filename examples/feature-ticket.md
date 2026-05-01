# Example Feature Ticket

## Phase 1 - Core Parser

Build the first minimal parser.

<!-- runner:model=mini -->
<!-- runner:verify=bash tests/core-parser.sh -->

### Requirements

- Read local input files.
- Return structured output.
- Add focused tests.

## Phase 2 - Report Writer

Generate a JSON and Markdown report from parser output.

<!-- runner:read=examples/reporting-notes.md -->
<!-- runner:verify=bash tests/report-writer.sh -->

### Requirements

- Keep reports deterministic.
- Preserve existing behavior.

## Phase 3 - Dashboard Widget

Add a small dashboard widget that surfaces the latest report.

<!-- runner:verify=bash tests/dashboard-widget.sh -->

### Requirements

- Keep the UI scoped.
- Do not redesign the application.
