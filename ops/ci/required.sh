#!/usr/bin/env bash
# Required lane: the lightweight gate that must pass on every push.
# Verifies the checkout was bootstrapped, then builds the package and runs the
# suite. Dependency and browser acquisition live in ops/ci/bootstrap.sh, so this
# lane needs no network and cannot fail on identical source.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

log "required lane: verify bootstrap + build + test"
bash ops/ci/check-bootstrap.sh
npm --workspace @jankurai/ux-qa run build
npm test
