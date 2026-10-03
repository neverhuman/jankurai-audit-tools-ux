# ops/ Agent Instructions

This cell owns the pinned CI entrypoints and local-parity tooling for
jankurai-tools-ux. Read the root [`AGENTS.md`](../AGENTS.md) first.

## Owns

- `ops/ci/*.sh` — the canonical lane scripts (`required`, `fast`, `security`,
  `audit`, `tool-adoption`, `quality-gates`) plus the shared `lib.sh` helpers.
- `ops/git-hooks/pre-push` — the mandatory pre-push gate that runs
  `bash ops/ci/quality-gates.sh`.
- The CI contract: CI on the forge and our hosts calls these scripts so local
  runs and CI execute identical commands.

## Forbidden

- Do not add GitHub Actions workflows; GitHub is a publishing mirror only.
- Do not weaken the security or audit lanes (no `continue-on-error`, no
  `|| true`, no nonblocking overrides).
- Do not hand-edit generated zones listed in
  [`agent/generated-zones.toml`](../agent/generated-zones.toml).

## Proof lane

Security lane and workflow lint:

```bash
bash scripts/ci-local.sh security   # gitleaks + npm audit --audit-level=high
bash scripts/ci-local.sh audit      # jankurai audit -> .jankurai/repo-score.{json,md}
bash scripts/ci-doctor.sh           # confirm local tools match CI pins
```
