# jankurai-tools-ux

<!-- jankurai-badge:start -->
[![Jankurai score: 91/100](agent/jankurai-badge.svg)](agent/jankurai-badge.json)
<!-- jankurai-badge:end -->

[![jankurai audit](https://img.shields.io/badge/jankurai-audit-passing-brightgreen)](.jankurai/repo-score.md)

UX QA tooling for the **jankurai** standard: a Playwright and axe wrapper that
emits deterministic, artifact-backed rendered UX proof receipts. This repository
is one member of the Jankurai split family; read [`SPLIT.md`](SPLIT.md) for the
family contract and [`AGENTS.md`](AGENTS.md) for agent routing rules.

## Stack

Node + TypeScript product surface driving a Playwright/axe rendered UX QA
runtime, with machine-readable JSON Schemas for its report and policy contracts.
New implementation is TypeScript-first; see
[`docs/architecture.md`](docs/architecture.md).

## Quick start

```bash
# One-command setup (install workspace dependencies from the lockfile).
just setup

# Deterministic fast lane (typecheck/build + tests + self-audit).
just fast

# Full local check: format, lint, fast, security, and self-audit.
just check
```

The full command surface lives in the root [`Justfile`](Justfile). Continuous
integration runs the same lanes on the forge and our own hosts. GitHub is a
publishing mirror only; it runs no workflows. Releases are built and signed on
our servers.

## Layout

| Path | Role |
| --- | --- |
| `packages/ux-qa` | TypeScript + Playwright rendered UX QA runtime and CLI |
| `schemas/` | JSON Schemas for the UX QA report and policy contracts |
| `tools/` | smoke-server harness for deterministic UX QA fixtures |
| `agent/` | machine-readable owner, test, boundary, and proof maps |
| `docs/` | architecture, testing, boundaries, release, and exception docs |
| `ops/` | pinned CI script entrypoints |
| `scripts/` | local CI and fusion helpers |

## Documentation

- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Boundaries](docs/boundaries.md)
- [Release process](docs/release.md)
- [Agent exceptions and overrides](docs/exceptions.md)

## Versioning

The current version is recorded in [`VERSION`](VERSION) and the change history in
[`CHANGELOG.md`](CHANGELOG.md). Release mechanics are documented in
[`docs/release.md`](docs/release.md).

## License

See [`LICENSE`](LICENSE).
