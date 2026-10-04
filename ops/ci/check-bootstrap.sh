#!/usr/bin/env bash
# Verify ops/ci/bootstrap.sh has run for this checkout: node_modules matches the
# current package-lock.json and the pinned Playwright browser is unpacked.
# Pure local inspection -- no registry and no browser CDN are contacted.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

[ -f "$BOOTSTRAP_STAMP" ] || bootstrap_hint "node_modules is missing or not bootstrapped"

stamped="$(cat "$BOOTSTRAP_STAMP")"
if [ "$stamped" != "$(lockfile_digest)" ]; then
  bootstrap_hint "node_modules was installed from a different package-lock.json"
fi

[ -f node_modules/playwright-core/browsers.json ] \
  || bootstrap_hint "playwright-core is missing from node_modules"

revision="$(playwright_headless_shell_revision)"
shell_dir="$(playwright_browsers_root)/chromium_headless_shell-$revision"
if [ ! -d "$shell_dir" ]; then
  bootstrap_hint "pinned chromium headless shell $revision is not installed in $(playwright_browsers_root)"
fi

log "bootstrap verified: lockfile digest matches, chromium headless shell $revision present"
