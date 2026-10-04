# Changelog

All notable changes to jankurai-tools-ux are documented in this file. The format
is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The authoritative version string lives in [`VERSION`](VERSION).

## [Unreleased]

### Changed

- Dependency and browser acquisition moved out of the gate lanes into
  `ops/ci/bootstrap.sh` (usable as a host setup hook). `ops/ci/required.sh` and
  `ops/ci/fast.sh` now verify the bootstrap offline through
  `ops/ci/check-bootstrap.sh` --- `node_modules` stamped with the current
  `package-lock.json` digest and the pinned Playwright chromium headless shell
  unpacked --- and fail with `run ops/ci/bootstrap.sh` otherwise, so a gate run
  no longer depends on the npm registry or the browser CDN.

### Removed

- GitHub Actions workflows (`.github/workflows/`), the GitHub job aggregate
  (`ops/ci/aggregate.sh`) and the actionlint/zizmor workflow lint steps. GitHub
  is a publishing mirror only; CI runs on the forge and our hosts.

### Changed

- `@jankurai/ux-qa` package version is `1.7.2`, matching the public CLI release (was `1.7.1`).

### Added

- Root `Justfile` command surface with `setup`, `fast`, `check`, `security`, and
  `audit` lanes for one-command setup and validation.
- GitHub Actions CI (`.github/workflows/ci.yml`) with build, security, and
  jankurai audit jobs, all third-party actions pinned to commit SHAs.
- Agent-readable documentation: `README.md`, `docs/architecture.md`,
  `docs/boundaries.md`, `docs/testing.md`, `docs/release.md`, and
  `docs/exceptions.md`.
- `agent/audit-policy.toml` with a `[scan]` exclusion list for transient build
  and dependency trees.

### Changed

- Re-scoped `agent/boundaries.toml`, `agent/owner-map.json`,
  `agent/test-map.json`, and `agent/generated-zones.toml` to the paths that
  exist in this single-purpose UX QA repo.

## [1.7.0] - 2026-06-12

### Added

- Initial split-family extraction of the `@jankurai/ux-qa` rendered UX QA
  package, schemas, and policy fixtures.
