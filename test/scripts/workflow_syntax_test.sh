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
if ! grep -q 'refs/tags/nightly\^{commit}' "$WORKFLOW"; then
  echo "FAIL: Missing commit-check dereferencing (refs/tags/nightly^{commit})"
  exit 1
fi

# 4. Verify signing secrets usage and consistency
if ! grep -q 'ANDROID_KEYSTORE_BASE64' "$WORKFLOW" || ! grep -q 'ANDROID_KEY_ALIAS' "$WORKFLOW"; then
  echo "FAIL: Missing keystore secrets references"
  exit 1
fi

if grep -q 'KEY_PASS=.*>> "\$GITHUB_ENV"' "$WORKFLOW" || grep -q 'KEYSTORE_PASS=.*>> "\$GITHUB_ENV"' "$WORKFLOW"; then
  echo "FAIL: Secret passwords should not be written to GITHUB_ENV file; pass via step env instead"
  exit 1
fi

if ! grep -q 'rm -f release.jks' "$WORKFLOW"; then
  echo "FAIL: Missing immediate cleanup/shredding of release.jks after signing"
  exit 1
fi

# 5. Verify real Flutter APK build and apksigner signing
if ! grep -q 'flutter build apk --release' "$WORKFLOW"; then
  echo "FAIL: Missing real flutter build apk --release step"
  exit 1
fi

if ! grep -q 'build/app/outputs/flutter-apk/app-release.apk' "$WORKFLOW"; then
  echo "FAIL: Missing reference to real compiled Flutter release APK"
  exit 1
fi

if (! grep -q 'apksigner sign' "$WORKFLOW" && ! grep -q '"\$APKSIGNER" sign' "$WORKFLOW") || ! grep -q -- '--min-sdk-version' "$WORKFLOW"; then
  echo "FAIL: Missing apksigner sign step with --min-sdk-version"
  exit 1
fi

# 6. Verify zero-clutter rolling release commands
if ! grep -q 'gh release delete nightly' "$WORKFLOW"; then
  echo "FAIL: Missing rolling release deletion command (gh release delete nightly)"
  exit 1
fi

if ! grep -q 'gh release create nightly' "$WORKFLOW" || ! grep -q -- '--prerelease' "$WORKFLOW" || ! grep -q -- '--target' "$WORKFLOW"; then
  echo "FAIL: Missing rolling release creation command with --prerelease and --target"
  exit 1
fi

echo "PASS: All workflow syntax and structure checks passed!"
