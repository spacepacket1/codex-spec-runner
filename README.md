# codex-spec-runner

Run Codex CLI phase-by-phase from Markdown feature specs with model routing, shared context, and resumable execution.

`codex-spec-runner` turns a phased Markdown spec into separate Codex CLI runs. Each phase gets a fresh conversation, a focused prompt, and a model selected from conservative defaults or explicit overrides.

## Why

Large implementation specs can waste context when every phase runs in one long conversation. This runner keeps each phase isolated so Codex starts with only the relevant spec section, the current working tree, and the files you tell it to read first.

## Requirements

- Bash
- `awk`, `grep`, `sort`
- Codex CLI installed and authenticated for normal execution and `--preflight`

Check Codex CLI:

```bash
codex --help
```

## Install

Clone the repo and add `bin` to your `PATH`:

```bash
git clone https://github.com/spacepacket1/codex-spec-runner.git
cd codex-spec-runner
export PATH="$PWD/bin:$PATH"
```

Or run it directly:

```bash
./bin/codex-spec-runner path/to/spec.md --list
```

## Spec Format

The spec should be Markdown with phase headings that include a phase number:

```md
## Phase 1 - Historical Replay
## Phase 2 - Walk-Forward Validation
## 6. Phase 3 - Execution Simulation
```

The runner extracts each phase section from its heading until the next phase heading.
Phase metadata is parsed once per runner process, sorted numerically, and duplicate phase numbers fail before Codex is launched.

## Usage

List phases and selected models:

```bash
codex-spec-runner docs/feature-ticket.md --list
```

Dry-run one phase prompt:

```bash
codex-spec-runner docs/feature-ticket.md 3 --dry-run
```

Run preflight checks only:

```bash
codex-spec-runner docs/feature-ticket.md --preflight
```

Prepare shared repo context only:

```bash
codex-spec-runner docs/feature-ticket.md --prepare-context
```

Run one phase:

```bash
codex-spec-runner docs/feature-ticket.md 3
```

Run all phases:

```bash
codex-spec-runner docs/feature-ticket.md all
```

Refresh shared repo context before execution:

```bash
codex-spec-runner docs/feature-ticket.md all --refresh-context
```

Resume from a phase after a rate limit or interruption:

```bash
codex-spec-runner docs/feature-ticket.md all --from 9
```

Run a bounded range:

```bash
codex-spec-runner docs/feature-ticket.md all --from 4 --to 8
```

Add files Codex should read first:

```bash
codex-spec-runner docs/feature-ticket.md 5 \
  --read package.json \
  --read pipeline.js \
  --read server.js
```

Recommended workflow for a new spec:

```bash
codex-spec-runner docs/feature-ticket.md --preflight
codex-spec-runner docs/feature-ticket.md --prepare-context
codex-spec-runner docs/feature-ticket.md all
```

Use `--refresh-context` when the repo changed enough that the shared context should be regenerated before execution.
Normal non-dry-run execution runs preflight automatically unless `SKIP_PREFLIGHT=1`; `--dry-run` remains usable without Codex installed.

## Runtime State

`.codex-spec-runner/` is runner runtime state. It is generated on demand and can contain:

- `context.md`: shared repo context used to reduce repeated setup across phases
- `manifest.tsv`: one tab-separated row per attempted phase run
- `summaries/phase-N.md`: lightweight per-phase summary placeholders

Shared context is opt-in for single-phase runs and automatic for `all` runs when `USE_SHARED_CONTEXT=1` and `context.md` does not already exist. It summarizes cheap local facts only: timestamp, root path, git status, top-level layout, detected package/config files, likely verification commands, and configured common read files.

Successful summaries from earlier phases are included in later `all` prompts by default, capped by `SUMMARY_LOOKBACK`.

These generated files are safe to delete:

- `.codex-spec-runner/context.md`
- `.codex-spec-runner/manifest.tsv`
- `.codex-spec-runner/summaries/`

Deleting them removes runner history and cached context, but does not affect your source files.

## Spec Annotations

Specs can override a phase model, add extra read files, and include verification hints with HTML comments inside the phase body:

```md
## Phase 2 - Report Writer

<!-- codex:model=gpt-5.4-mini -->
<!-- codex:read=docs/reporting-notes.md -->
<!-- codex:verify=bash tests/reporting.sh -->
```

- `codex:model` overrides heuristic routing for that phase
- `codex:read` adds files to the "Read first" block
- `codex:verify` adds prompt-only verification hints

See [examples/feature-ticket.md](examples/feature-ticket.md) for a complete example.

## Model Routing

Default routing is intentionally conservative:

- `gpt-5.5` for phases whose title suggests custody, wallets, routing, MEV/gas, reconciliation/accounting/tax, compliance, audit, or permissions.
- `gpt-5.4` for most implementation phases.
- `gpt-5.4-mini` is available for explicit overrides.

Override exact phase-to-model mapping:

```bash
MODEL_OVERRIDES="4:gpt-5.5,14:gpt-5.4-mini" \
  codex-spec-runner docs/feature-ticket.md all
```

Override default model names:

```bash
DEFAULT_MODEL=gpt-5.4 \
HIGH_MODEL=gpt-5.5 \
MINI_MODEL=gpt-5.4-mini \
  codex-spec-runner docs/feature-ticket.md --list
```

## Configuration

The runner invokes Codex like this:

```bash
codex --model "$model" --cd "$ROOT_DIR" --sandbox "$SANDBOX_MODE" --ask-for-approval "$APPROVAL_POLICY" --ephemeral exec -
```

Environment overrides:

```bash
ROOT_DIR=/path/to/repo
STATE_DIR=/path/to/repo/.codex-spec-runner
CONTEXT_FILE=/path/to/repo/.codex-spec-runner/context.md
MANIFEST_FILE=/path/to/repo/.codex-spec-runner/manifest.tsv
SUMMARY_DIR=/path/to/repo/.codex-spec-runner/summaries
CODEX_BIN=codex
SKIP_PREFLIGHT=0
USE_SHARED_CONTEXT=1
USE_PHASE_SUMMARIES=1
SUMMARY_LOOKBACK=1
SANDBOX_MODE=workspace-write
APPROVAL_POLICY=on-request
MODE=exec
CODEX_EPHEMERAL=1
DEFAULT_MODEL=gpt-5.4
HIGH_MODEL=gpt-5.5
MINI_MODEL=gpt-5.4-mini
MODEL_OVERRIDES="4:gpt-5.5,14:gpt-5.4-mini"
COMMON_READ_FILES="package.json pipeline.js server.js"
```

- `STATE_DIR`, `CONTEXT_FILE`, `MANIFEST_FILE`, `SUMMARY_DIR`: runtime-state paths under `.codex-spec-runner/`
- `CODEX_BIN`: Codex CLI binary name or path
- `SKIP_PREFLIGHT`: set to `1` to skip automatic preflight on normal runs
- `USE_SHARED_CONTEXT`: set to `0` to omit `context.md` from prompts
- `USE_PHASE_SUMMARIES`: set to `0` to omit prior phase summaries from later prompts
- `SUMMARY_LOOKBACK`: number of previous successful summaries to include during `all`
- `SANDBOX_MODE`, `APPROVAL_POLICY`, `MODE`: passed through to Codex CLI
- `CODEX_EPHEMERAL`: set to `0` to let Codex persist phase sessions; default `1` avoids stale session persistence during runner-managed phase runs
- `DEFAULT_MODEL`, `HIGH_MODEL`, `MINI_MODEL`: default routed model names
- `MODEL_OVERRIDES`: exact `phase:model` mapping that beats heuristic routing and spec annotations
- `COMMON_READ_FILES`: space-separated files to include in every phase prompt when present

Manifest and summary behavior:

- `manifest.tsv` records each attempted phase run, including dry-runs and non-zero exits
- `summaries/phase-N.md` is updated after each attempted phase with timestamp, model, exit status, and a human-notes section
- later phases in `all` can read recent successful summaries unless `USE_PHASE_SUMMARIES=0`

## Safety Notes

The generated prompt tells Codex to:

- keep edits scoped to the current phase
- preserve existing behavior unless the phase requires a change
- avoid `node_modules`
- avoid later phases
- inspect the working tree when resuming after an interrupted run
- run verification before finishing

You should still review diffs after each phase.

## License

MIT
