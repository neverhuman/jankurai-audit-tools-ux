# jankurai-tools-ux Testing

Testing is routed proof. Agents should not guess which tests matter; route
through [`agent/test-map.json`](../agent/test-map.json) and
[`agent/proof-lanes.toml`](../agent/proof-lanes.toml) to the smallest lane that
covers the change.

| Lane | Purpose |
| --- | --- |
| `fast` | deterministic local proof for most edits (build + tests + self-audit) |
| `web` | TypeScript build/typecheck and the rendered UX QA test suite |
| `e2e` | Playwright UX QA specs over the deterministic smoke server |
| `security` | secret scanning plus dependency vulnerability scanning |
| `audit` | jankurai repo score and hard-rule findings |
| `full` | release/merge gate (all of the above) |

## Fast lane

The fast lane is the narrowest proof loop for agent iteration. Locally it runs
through `just fast` and `bash scripts/ci-local.sh fast`, which execute the same
`ops/ci/fast.sh` script CI runs:

```bash
npx vitest run            # workspace unit/spec tests (or `npm test` for the
                          # @jankurai/ux-qa package test script)
jankurai audit . --no-score-history \
  --json .jankurai/repo-score.json --md .jankurai/repo-score.md   # repo-score
```

In this Playwright-backed package, `npm test` resolves to
`env -u NO_COLOR playwright test`; `npx vitest run` is the equivalent
deterministic unit runner when present. Either way the fast lane stays
hermetic and writes the `repo-score` artifacts CI uploads.

## Rendered UX QA

Rendered UX QA combines Playwright screenshots, ARIA snapshots, deterministic
visual-baseline hashes and optional pixel-diff receipts, axe/WCAG checks, and
deterministic DOM geometry rules such as edge clearance, target size, overlap,
clipping, wrapping, horizontal overflow, sticky obstruction, focus visibility,
form labels, and nested scrollbars.

Critical UI proof must be artifact-backed. A useful receipt names the route or
story, browser, viewport, action sequence, screenshot or crop path, ARIA
snapshot path when available, sha256 artifact digests, rule IDs, selectors,
owner, and merge decision. Deterministic rule violations block; visual baselines
compare file bytes and hashes, not pixels or AI/VLM judgment; review only applies
to owner-approved baseline changes or ambiguous product calls.

The test corpus lives under `packages/ux-qa/tests/` and drives the deterministic
smoke server in `tools/ux-qa-smoke-server.mjs`. Specs cover geometry, artifact
coverage, config parsing/rejection, the route/state matrix, hit-testing,
selector resolution, Storybook ingestion, and visual baselines.

## Schema-first work

For new contract files under `schemas/`, add a spec that loads the JSON Schema
and checks the required fields or references the contract chain before wiring new
CLI surface. Keep that proof under the package test script so the schema stays
machine-readable while the CLI surface is still being planned.

`schemas/ux-qa.schema.json` is the report contract and
`schemas/ux-qa-policy.schema.json` is the policy contract; both are validated by
the package test suite. Artifacts in reports must be relative to the repo or the
configured output root.

## Observability and repair receipts

The CLI emits structured, repo-relative report envelopes with request/route
identifiers, per-rule decisions, and sha256 artifact digests so the next agent
can rerun proof from the receipt rather than from chat history.

Every failure carries a typed repair hint rather than a raw stack trace. A repair
receipt records:

- `command` and `exit_code` — exactly what ran and how it ended.
- `changed_paths` and `artifacts` — what the lane touched and produced.
- `purpose`, `reason`, and `common_fixes` — why the check exists and how to
  resolve it.
- `repair_hint` and `docs_url` — the narrowest next action and where to read more.
- `rerun_command` — the exact command the next agent should trust to re-prove.

Phase closeouts cite the exact receipt path instead of relying on chat history.
Prefer structured errors, telemetry, and repair receipts that tell the next agent
where to rerun proof over free-form logging.

## Cost and budget

The fast lane is bounded: the unit/spec runner and the no-write jankurai audit
both complete well within the CI lane timeouts declared in
[`agent/proof-lanes.toml`](../agent/proof-lanes.toml). Full Playwright browser
runs are reserved for the `e2e`/`full` lanes so day-to-day iteration stays cheap.
There are no paid or unbounded external calls in any lane; the explicit budget,
quota, stop condition, and kill-switch for each lane is the `timeout_seconds`
declared per lane in [`agent/proof-lanes.toml`](../agent/proof-lanes.toml), after
which the lane aborts.

## Launch-gate evidence

The `full` release/merge gate does not claim release readiness on prose alone.
Every launch-gate dimension is backed by a real artifact or command, documented
in [`docs/release.md`](release.md):

- **Security**: the `security` lane runs `gitleaks detect` and
  `npm audit --audit-level=high`; CI uploads the result.
- **Integrity and backups**: `package-lock.json` is committed and CI installs
  with `npm ci`, so any release can be reinstalled bit-for-bit from its immutable
  tag; the SBOM is generated as `sbom.json`.
- **Monitoring**: the `audit` lane writes `.jankurai/repo-score.json` and
  `.jankurai/repo-score.md`, the monitored score artifacts CI uploads on every
  run so regressions and new findings are observable before merge.
- **Rollback**: the documented rollback procedure re-points consumers at the last
  known-good immutable tag; tags are never moved or deleted.
- **Abuse and rate limits**: the UX QA runtime makes no outbound network calls in
  CI lanes (the deterministic smoke server is local), so there is no external
  rate-limit or abuse surface to gate; any future networked surface must add rate
  limiting before its lane is promoted to the release gate.

## Security

The security lane runs `gitleaks detect` for committed-secret scanning and
`npm audit --audit-level=high` for dependency vulnerability scanning, the same
commands locally (`just security`) and in CI (`ops/ci/security.sh`).
