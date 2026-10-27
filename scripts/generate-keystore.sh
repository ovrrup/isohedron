#!/usr/bin/env bash
set -euo pipefail

OUTPUT="isohedron-release.jks"
ALIAS="isohedron"
PASSWORD=""
DNAME="/CN=Isohedron/OU=Release/O=Isohedron/C=US"
DAYS="10000"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --alias)
      ALIAS="$2"
      shift 2
      ;;
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    --dname)
      DNAME="$2"
      shift 2
      ;;
    --days)
      DAYS="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$PASSWORD" ]]; then
  # Generate strong random 24-character password if none provided
  PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 24)
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

KEY_PEM="$TMP_DIR/key.pem"
CERT_PEM="$TMP_DIR/cert.pem"

echo "Generating Android release signing key..."
openssl req -x509 -newkey rsa:2048 \
  -keyout "$KEY_PEM" \
  -out "$CERT_PEM" \
  -days "$DAYS" \
  -nodes \
  -subj "$DNAME" 2>/dev/null

echo "Exporting to PKCS#12 Android keystore format..."
openssl pkcs12 -export \
  -in "$CERT_PEM" \
  -inkey "$KEY_PEM" \
  -out "$OUTPUT" \
  -name "$ALIAS" \
  -passout "pass:$PASSWORD"

chmod 600 "$OUTPUT"

B64_KEYSTORE=$(base64 -w 0 "$OUTPUT" 2>/dev/null || base64 "$OUTPUT")

echo "=== Android Signing Keystore Generated Successfully ==="
echo "Keystore Path: $OUTPUT"
echo "Key Alias:     $ALIAS"
echo "Key Password:  $PASSWORD"
echo "Validity:      $DAYS days"
echo ""
echo "To configure GitHub Repository Secrets for automated CI signing, run:"
echo "gh secret set ANDROID_KEYSTORE_BASE64 --body \"$B64_KEYSTORE\""
echo "gh secret set ANDROID_KEY_ALIAS --body \"$ALIAS\""
echo "gh secret set ANDROID_KEY_PASSWORD --body \"$PASSWORD\""
echo "gh secret set ANDROID_KEYSTORE_PASSWORD --body \"$PASSWORD\""
