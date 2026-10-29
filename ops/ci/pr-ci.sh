#!/usr/bin/env bash
# Hosted dependency setup, then the unchanged offline required proof.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

log "hosted setup: locked Node dependencies"
bash ops/ci/bootstrap.sh
exec bash scripts/ci-local.sh required
