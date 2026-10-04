#!/usr/bin/env bash
# Shared CI helper module sourced by every ops/ci/<lane>.sh script.
# Single source of truth for tool version pins and artifact assertions so
# local runs and the CI hosts execute the exact same commands.
set -euo pipefail

# Resolve the repository root regardless of where a lane is invoked from.
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export REPO_ROOT

# Pinned tool versions. Lanes read these so CI and local environments match.
export NODE_VERSION="${NODE_VERSION:-20}"
export GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.18.4}"
export NPM_AUDIT_LEVEL="${NPM_AUDIT_LEVEL:-high}"

# log <message> -- emit a structured progress line.
log() {
  printf '[ci] %s\n' "$*"
}

# require_tool <binary> -- fail fast with an actionable message when a pinned
# tool is missing from PATH so local parity gaps surface before the lane runs.
require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '[ci] missing required tool: %s\n' "$tool" >&2
    return 1
  fi
}

# assert_artifact <path> -- confirm a lane produced the artifact it promised.
assert_artifact() {
  local artifact="$1"
  if [ ! -e "$REPO_ROOT/$artifact" ]; then
    printf '[ci] expected artifact missing: %s\n' "$artifact" >&2
    return 1
  fi
  log "artifact present: $artifact"
}

# Bootstrap contract ------------------------------------------------------
# Dependency and browser acquisition is the one step that needs the network.
# It lives in ops/ci/bootstrap.sh (used as the setup hook) and leaves a stamp
# behind; the lanes only verify the stamp, so a gate run never reaches out to
# the npm registry or the browser CDN.

# Stamp written by ops/ci/bootstrap.sh once install succeeded.
export BOOTSTRAP_STAMP="${BOOTSTRAP_STAMP:-node_modules/.jankurai-bootstrap}"

# bootstrap_hint <reason> -- fail with the single actionable line the lanes promise.
bootstrap_hint() {
  printf '[ci] %s: run ops/ci/bootstrap.sh\n' "$1" >&2
  return 1
}

# lockfile_digest -- content digest of the lockfile the install must match.
lockfile_digest() {
  sha256sum "$REPO_ROOT/package-lock.json" | cut -d' ' -f1
}

# playwright_browsers_root -- directory Playwright unpacks browsers into.
playwright_browsers_root() {
  printf '%s\n' "${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
}

# playwright_headless_shell_revision -- pinned chromium headless shell build,
# read from the installed playwright-core so it tracks the lockfile, not a
# second copy of the version number.
playwright_headless_shell_revision() {
  node -e '
    const path = process.argv[1] + "/node_modules/playwright-core/browsers.json";
    const found = require(path).browsers.find((b) => b.name === "chromium-headless-shell");
    if (!found) throw new Error("chromium-headless-shell missing from browsers.json");
    process.stdout.write(found.revision);
  ' "$REPO_ROOT"
}
