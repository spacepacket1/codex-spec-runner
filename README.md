# codex-spec-runner

Run Codex CLI phase-by-phase from Markdown feature specs with model routing and resumable execution.

`codex-spec-runner` turns a phased Markdown spec into separate Codex CLI runs. Each phase gets a fresh conversation, a focused prompt, and a model selected from conservative defaults or explicit overrides.

## Why

Large implementation specs can waste context when every phase runs in one long conversation. This runner keeps each phase isolated so Codex starts with only the relevant spec section, the current working tree, and the files you tell it to read first.

## Requirements

- Bash
- `awk`, `grep`, `sort`
- Codex CLI installed and authenticated

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

## Usage

List phases and selected models:

```bash
codex-spec-runner docs/feature-ticket.md --list
```

Dry-run one phase prompt:

```bash
codex-spec-runner docs/feature-ticket.md 3 --dry-run
```

Run one phase:

```bash
codex-spec-runner docs/feature-ticket.md 3
```

Run all phases:

```bash
codex-spec-runner docs/feature-ticket.md all
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

## Codex CLI Options

The runner invokes Codex like this:

```bash
codex --model "$model" --cd "$ROOT_DIR" --sandbox "$SANDBOX_MODE" --ask-for-approval "$APPROVAL_POLICY" exec -
```

Environment overrides:

```bash
ROOT_DIR=/path/to/repo
CODEX_BIN=codex
SANDBOX_MODE=workspace-write
APPROVAL_POLICY=on-request
MODE=exec
COMMON_READ_FILES="package.json pipeline.js server.js"
```

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
