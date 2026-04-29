#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="${REPO_DIR}/bin/codex-spec-runner"
SPEC_FILE="${REPO_DIR}/examples/feature-ticket.md"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-spec-runner-phase10.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

PATH="${REPO_DIR}/bin:${PATH}"

bash -n "$RUNNER"

version_output="$(
  cd "$REPO_DIR" &&
  codex-spec-runner --version
)"
printf '%s\n' "$version_output" | grep -F "codex-spec-runner 0.1.3" >/dev/null

list_output="$(
  cd "$REPO_DIR" &&
  codex-spec-runner "$SPEC_FILE" --list
)"
printf '%s\n' "$list_output" | grep -F $'Phase 1\tgpt-5.4-mini\tCore Parser' >/dev/null

preflight_output="$(
  cd "$REPO_DIR" &&
  codex-spec-runner "$SPEC_FILE" --preflight
)"
printf '%s\n' "$preflight_output" | grep -F "result: ok with 1 warning(s)" >/dev/null

phase_dry_run_output="$(
  cd "$REPO_DIR" &&
  codex-spec-runner "$SPEC_FILE" 1 --dry-run
)"
printf '%s\n' "$phase_dry_run_output" | grep -F "== Phase 1: Core Parser ==" >/dev/null
printf '%s\n' "$phase_dry_run_output" | grep -F "Status: dry-run only; Codex was not started." >/dev/null
if printf '%s\n' "$phase_dry_run_output" | grep -F -- "--- prompt ---" >/dev/null; then
  echo "default dry-run unexpectedly printed full prompt" >&2
  exit 1
fi

verbose_phase_dry_run_output="$(
  cd "$REPO_DIR" &&
  codex-spec-runner "$SPEC_FILE" 1 --dry-run --verbose
)"
printf '%s\n' "$verbose_phase_dry_run_output" | grep -F -- "--- prompt ---" >/dev/null

all_dry_run_output="$(
  cd "$REPO_DIR" &&
  codex-spec-runner "$SPEC_FILE" all --dry-run
)"
printf '%s\n' "$all_dry_run_output" | grep -F "== Phase 3: Dashboard Widget ==" >/dev/null

unset_verbose_output="$(
  cd "$REPO_DIR" &&
  unset VERBOSE &&
  codex-spec-runner "$SPEC_FILE" all --from 1 --to 1 --dry-run
)"
printf '%s\n' "$unset_verbose_output" | grep -F "Status: dry-run only; Codex was not started." >/dev/null

fake_codex="${TMP_DIR}/codex"
fake_args="${TMP_DIR}/codex-args"
fake_stdin="${TMP_DIR}/codex-stdin"
mkdir -p "${TMP_DIR}/root"
cat > "$fake_codex" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$FAKE_ARGS"
cat > "$FAKE_STDIN"
EOF
chmod +x "$fake_codex"

(
  cd "$REPO_DIR" &&
  COMMON_READ_FILES="" \
  ROOT_DIR="${TMP_DIR}/root" \
  CODEX_BIN="$fake_codex" \
  FAKE_ARGS="$fake_args" \
  FAKE_STDIN="$fake_stdin" \
  "$RUNNER" "$SPEC_FILE" 1
) >/dev/null

grep -Fx -- "--ephemeral" "$fake_args" >/dev/null
first_four_args="$(sed -n '1,4p' "$fake_args")"
[[ "$first_four_args" == $'--ask-for-approval\non-request\nexec\n--ephemeral' ]]
grep -F "Implement Phase 1 (Core Parser)" "$fake_stdin" >/dev/null

echo "phase-10-final-verification: ok"
