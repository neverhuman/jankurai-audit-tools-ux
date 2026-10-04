# jankurai-tools-ux root command surface.
# One-command setup and validation lanes for agents and CI.
# Every lane below is deterministic, hermetic, and runnable from the repo root.

# Default: list available lanes.
default:
    @just --list

# One-command bootstrap: install the workspace dependencies and the pinned
# Playwright browser. The only lane allowed to use the network.
setup:
    bash ops/ci/bootstrap.sh
    npm --workspace @jankurai/ux-qa run build

# Alias for setup so `just install` and `just bootstrap` also resolve.
install: setup

bootstrap: setup

# Deterministic fast lane: the narrowest proof loop for agent iteration.
# Build the package, run the test suite, and write the jankurai repo-score.
fast:
    npm --workspace @jankurai/ux-qa run build
    npm test
    jankurai audit . --no-score-history --json .jankurai/repo-score.json --md .jankurai/repo-score.md

# Run the full local check: format, lint, fast lane, security, and audit.
check: fmt lint fast security audit

# Verify is an alias of check for agents that look for a `verify` lane.
verify: check

fmt:
    npx prettier --check .

lint:
    npx tsc --noEmit -p packages/ux-qa/tsconfig.json

# Run the workspace test suite.
test:
    npm test

# Security lane: secret scanning plus dependency vulnerability scanning.
# gitleaks scans for committed secrets; npm audit checks the npm dependency tree.
security:
    bash tools/security-lane.sh

# Jankurai self-audit lane: writes the repo-score artifacts that CI uploads.
audit:
    jankurai audit . --no-score-history --json .jankurai/repo-score.json --md .jankurai/repo-score.md

# Print the declared version.
versions:
    cat VERSION
