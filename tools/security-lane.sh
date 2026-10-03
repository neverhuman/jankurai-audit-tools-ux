#!/usr/bin/env bash
# Canonical security lane wrapper for jankurai-tools-ux.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p target

echo "[security] secret scan: gitleaks detect"
gitleaks detect --source . --no-banner --redact

echo "[security] npm audit"
npm audit --audit-level=high

echo "[security] SBOM / provenance: hash published package sources"
find packages schemas contracts README.md AGENTS.md -type f | sort | xargs sha256sum > target/sbom.txt
echo "[security] sbom written to target/sbom.txt"
