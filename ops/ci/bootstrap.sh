#!/usr/bin/env bash
# Bootstrap: the only step that is allowed to use the network.
# Installs the locked dependency graph and the pinned Playwright browser, then
# stamps node_modules so the lanes can verify the result offline. Run this once
# per checkout (the queue uses it as the setup hook); the gate lanes never
# install anything themselves.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

# BOOTSTRAP_WITH_DEPS=1 also installs the system libraries the browser needs;
# hosts that already provide them (our CI images) leave it unset.
install_args=(chromium --only-shell)
if [ "${BOOTSTRAP_WITH_DEPS:-0}" = 1 ]; then
  install_args=(--with-deps "${install_args[@]}")
fi

log "bootstrap: npm ci + pinned Playwright chromium headless shell"
npm ci
npm exec -- playwright install "${install_args[@]}"

revision="$(playwright_headless_shell_revision)"
shell_dir="$(playwright_browsers_root)/chromium_headless_shell-$revision"
if [ ! -d "$shell_dir" ]; then
  printf '[ci] playwright install did not produce %s\n' "$shell_dir" >&2
  exit 1
fi

printf '%s\n' "$(lockfile_digest)" > "$BOOTSTRAP_STAMP"
log "bootstrap complete: lockfile digest stamped, chromium headless shell $revision in $(playwright_browsers_root)"
