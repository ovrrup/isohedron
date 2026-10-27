#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/generate-keystore.sh"

echo "=== Running Keystore Generation Tests ==="

# 1. Verify script exists
if [[ ! -f "$SCRIPT" ]]; then
  echo "FAIL: $SCRIPT does not exist"
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

KEYSTORE_PATH="$TMP_DIR/isohedron-test.jks"
ALIAS="test-isohedron"
PASS="testpass123"

# 2. Run generation script
bash "$SCRIPT" \
  --output "$KEYSTORE_PATH" \
  --alias "$ALIAS" \
  --password "$PASS" \
  --dname "/CN=IsohedronTest/O=Isohedron/C=US"

# 3. Verify keystore was created and is non-empty
if [[ ! -s "$KEYSTORE_PATH" ]]; then
  echo "FAIL: Keystore file was not created or is empty"
  exit 1
fi

# 4. Verify PKCS#12 validity with openssl
if ! openssl pkcs12 -info -in "$KEYSTORE_PATH" -passin "pass:$PASS" -noout 2>/dev/null; then
  echo "FAIL: Keystore is not a valid PKCS#12 bundle"
  exit 1
fi

# 5. Verify base64 export works
B64=$(base64 -w 0 "$KEYSTORE_PATH" 2>/dev/null || base64 "$KEYSTORE_PATH")
if [[ -z "$B64" ]]; then
  echo "FAIL: Base64 string is empty"
  exit 1
fi

# 6. Verify .gitignore covers keystores
if ! grep -q '\*\.jks' "$REPO_ROOT/.gitignore" || ! grep -q '\*\.keystore' "$REPO_ROOT/.gitignore"; then
  echo "FAIL: .gitignore does not protect *.jks or *.keystore"
  exit 1
fi

echo "PASS: All keystore generation and safety tests passed!"
