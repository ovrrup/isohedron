#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW="$REPO_ROOT/.github/workflows/nightly.yml"

echo "=== Running Workflow Syntax & Specification Tests ==="

if [[ ! -f "$WORKFLOW" ]]; then
  echo "FAIL: $WORKFLOW does not exist"
  exit 1
fi

# 1. Verify triggers
if ! grep -q 'schedule:' "$WORKFLOW" || ! grep -q 'workflow_dispatch:' "$WORKFLOW"; then
  echo "FAIL: Missing schedule or workflow_dispatch trigger"
  exit 1
fi

# 2. Verify permissions
if ! grep -q 'contents: write' "$WORKFLOW"; then
  echo "FAIL: Missing 'contents: write' permission"
  exit 1
fi

# 3. Verify commit-checking logic
if ! grep -q 'refs/tags/nightly' "$WORKFLOW" && ! grep -q 'git rev-parse' "$WORKFLOW"; then
  echo "FAIL: Missing commit-check comparison against nightly tag"
  exit 1
fi

# 4. Verify signing secrets usage
if ! grep -q 'ANDROID_KEYSTORE_BASE64' "$WORKFLOW" || ! grep -q 'ANDROID_KEY_ALIAS' "$WORKFLOW"; then
  echo "FAIL: Missing keystore secrets references"
  exit 1
fi

# 5. Verify apksigner signing
if ! grep -q 'apksigner sign' "$WORKFLOW"; then
  echo "FAIL: Missing apksigner sign step"
  exit 1
fi

# 6. Verify zero-clutter rolling release commands
if ! grep -q 'gh release delete nightly' "$WORKFLOW"; then
  echo "FAIL: Missing rolling release deletion command (gh release delete nightly)"
  exit 1
fi

if ! grep -q 'gh release create nightly' "$WORKFLOW" || ! grep -q -- '--prerelease' "$WORKFLOW"; then
  echo "FAIL: Missing rolling release creation command (gh release create nightly ... --prerelease)"
  exit 1
fi

echo "PASS: All workflow syntax and structure checks passed!"
