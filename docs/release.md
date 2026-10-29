# Release process

This document is the release control surface for jankurai-tools-ux. It covers the
version source, the changelog, the release automation, integrity and SBOM
evidence, and rollback. Launch gates require every section below to be backed by
a real artifact or command.

## Version source

The single source of truth for the version is the [`VERSION`](../VERSION) file at
the repository root. The package version in `packages/ux-qa/package.json` and any
release tag MUST match `VERSION`. Tags follow the family pattern
`jankurai-tools-ux-v<MAJOR.MINOR.PATCH>-split.<N>` as described in
[`SPLIT.md`](../SPLIT.md).

## Changelog

Release notes are generated at release time from the commits since the previous
release, using commit subjects and `Todo:` trailers. The generated notes are
recorded in [`CHANGELOG.md`](../CHANGELOG.md) under a heading that matches the
new `VERSION`; keep the `Unreleased` heading in place for release tooling.

The release preparer runs this command before creating the release PR. Set
`PREVIOUS_RELEASE_TAG` to the last published release tag; `VERSION` must already
name the candidate version:

```sh
: "${PREVIOUS_RELEASE_TAG:?set the previous published release tag}"
git rev-parse --verify "refs/tags/$PREVIOUS_RELEASE_TAG^{commit}"
git merge-base --is-ancestor "$PREVIOUS_RELEASE_TAG" HEAD
version=$(cat VERSION)
mkdir -p target/release-notes
{
  printf '## %s\n\n' "$version"
  git log --reverse --no-merges --format='- %s%n%(trailers:key=Todo)' "$PREVIOUS_RELEASE_TAG..HEAD"
} > "target/release-notes/$version.md"
```

Review that generated file for compatibility changes and rollback commits, then
insert the version block into `CHANGELOG.md` in the release PR. Preserve all
historical entries and carry existing pending `Unreleased` notes into the
release they describe. The command above performs generation; publication does
not invoke an implicit generator. Record rollback details in the revert commit
so the same command includes them in the next release.

## Release automation

Releases are cut by CI, not by hand:

1. Bump [`VERSION`](../VERSION) and promote the `Unreleased` section of
   [`CHANGELOG.md`](../CHANGELOG.md) to a dated version heading with generated
   notes from the commits since the last release.
2. Run the full local gate: `just check` (format, lint, fast lane, security,
   self-audit).
3. Push the version commit through a forge pull request. CI on the forge and
   our hosts runs the build, security, and jankurai audit lanes.
4. Tag the release commit with `jankurai-tools-ux-v<version>-split.<N>`. The tag
   mirror in [`.jeryu/repo.toml`](../.jeryu/repo.toml) publishes the immutable tag
   to the public GitHub mirror.

Release builds depend on immutable tags, never branches.

## Integrity, provenance, and SBOM

- **Dependency integrity**: builds are reproducible because
  [`package-lock.json`](../package-lock.json) is committed and CI installs with
  `npm ci` (lockfile-exact), never `npm install`.
- **SBOM**: generate a CycloneDX software bill of materials from the locked
  dependency graph with `npx @cyclonedx/cyclonedx-npm --output-file sbom.json`
  (run in CI alongside the security job) and attach it to the release as
  `sbom.json`.
- **Provenance**: the security job runs `gitleaks detect` for secret scanning and
  `npm audit --audit-level=high` for dependency advisories; the audit job
  publishes the `repo-score` artifacts that prove the release passed the jankurai
  gate.
- **Build hosts**: GitHub is a publishing mirror and runs no workflows. Releases
  are built and signed on our servers; a separate change introduces key-based
  release signing.

## Rollback

If a release regresses:

1. Identify the last known-good tag
   (`jankurai-tools-ux-v<version>-split.<N>`).
2. Re-point consumers at that immutable tag; tags are never moved or deleted.
3. Open a revert commit that restores the previous `VERSION` and `CHANGELOG.md`
   state.
4. Re-run `just check` to confirm the rolled-back tree is green before
   re-publishing.

Because tags are immutable and `package-lock.json` is committed, any prior
release can be reinstalled exactly from its tag.
