#!/bin/bash
set -uo pipefail

# Autoresearch measure: MagicX Zero 28 board-port validation via GitHub Actions.
#
# The full 180 GiB image build needs a self-hosted x64 runner (unavailable).
# Instead we validate the port on a GitHub-hosted runner, which catches port
# regressions (DTS, boot scripts, partition references, missing files) that
# would otherwise only surface after a multi-hour build.
#
# Primary metric = validation_ok (1 = validate workflow green, 0 otherwise).

REPO="jellydn/knulli-zero-28"
WORKFLOW="validate-magicx-zero-28.yml"
REF=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo knulli-main)

# A workflow can only be dispatched from a ref that contains its file.
if ! git ls-tree -r --name-only "origin/$REF" 2>/dev/null | grep -qx ".github/workflows/$WORKFLOW"; then
  REF="knulli-main"
fi

command -v gh >/dev/null 2>&1 || { echo "METRIC validation_ok=0"; echo "gh CLI missing" >&2; exit 0; }

# Dispatch the validation workflow (explicit --ref so it works from this branch)
gh workflow run "$WORKFLOW" --repo "$REPO" --ref "$REF" >/dev/null 2>&1 || {
  echo "METRIC validation_ok=0"
  echo "dispatch failed" >&2
  exit 0
}

# Wait briefly for the run to appear, then resolve its id.
RUN_ID=""
for _ in $(seq 1 10); do
  RUN_ID=$(gh run list --repo "$REPO" --workflow "$WORKFLOW" --limit 1 --json databaseId,status -q '.[0].databaseId' 2>/dev/null || true)
  [ -n "$RUN_ID" ] && break
  sleep 3
done

if [ -z "$RUN_ID" ]; then
  echo "METRIC validation_ok=0"
  echo "could not resolve run id" >&2
  exit 0
fi

echo "Dispatched validation run $RUN_ID; waiting..." >&2
START_TS=$(date +%s)

# Wait for completion (github-hosted validate is quick; bound at 15 min)
WAIT_MAX=$(( 15 * 60 ))
POLL=20
while true; do
  CONCLUSION=$(gh run view "$RUN_ID" --repo "$REPO" --json conclusion -q '.conclusion' 2>/dev/null || echo "")
  case "$CONCLUSION" in
    success|failure|cancelled|timed_out|skipped) break ;;
    *)
      ELAPSED=$(( $(date +%s) - START_TS ))
      if [ "$ELAPSED" -ge "$WAIT_MAX" ]; then
        echo "METRIC validation_ok=0"
        echo "METRIC build_minutes=$(( ELAPSED / 60 ))"
        echo "timed out waiting for run $RUN_ID" >&2
        exit 0
      fi
      sleep "$POLL"
      ;;
  esac
done

END_TS=$(date +%s)
BUILD_MINUTES=$(( (END_TS - START_TS) / 60 ))
echo "Run $RUN_ID concluded: $CONCLUSION" >&2

if [ "$CONCLUSION" = "success" ]; then
  echo "METRIC validation_ok=1"
else
  echo "METRIC validation_ok=0"
fi
echo "METRIC build_minutes=$BUILD_MINUTES"
