#!/usr/bin/env bash
# Deterministic fast lane: the narrowest proof loop for agent iteration.
# Identical command set is exposed locally via `just fast` and
# `bash scripts/ci-local.sh fast`. Dependencies and the pinned browser come
# from ops/ci/bootstrap.sh, never from this lane.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

log "fast lane: verify bootstrap + build + Playwright + jankurai audit"
bash ops/ci/check-bootstrap.sh
npm --workspace @jankurai/ux-qa run build
npm test
mkdir -p .jankurai
jankurai audit . --no-score-history --json .jankurai/repo-score.json --md .jankurai/repo-score.md --full

assert_artifact .jankurai/repo-score.json
assert_artifact .jankurai/repo-score.md
