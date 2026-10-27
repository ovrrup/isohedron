# Android Release Signing & Security Guide

This document details how **Isohedron** signs Android release builds, manages keystore credentials securely, and verifies package integrity.

---

## 1. Overview & Security Principles

* **Git Cleanliness:** Private keystores (`*.jks`, `*.keystore`, `*.p12`) and `key.properties` are strictly blocked by `.gitignore`. They must **never** be committed to the public repository.
* **CI/CD Signing:** Release signing is automated inside GitHub Actions via `apksigner` using encrypted GitHub Repository Secrets.
* **Format:** Keys are generated as standard **PKCS#12** keystores (RSA 2048-bit, 10,000 days validity), compatible with both modern Java/Android build-tools and OpenSSL.

---

## 2. Generating Signing Credentials

To generate a new Android release signing keystore, run:

```bash
bash scripts/generate-keystore.sh \
  --output isohedron-release.jks \
  --alias isohedron \
  --dname "/CN=Isohedron/OU=Release/O=Isohedron/C=US" \
  --days 10000
```

The script will:
1. Create a secure RSA 2048-bit key and self-signed X.509 certificate.
2. Export the key bundle to a PKCS#12 `.jks` file with `0600` permissions.
3. Output the base64-encoded string and exact `gh secret set` commands to configure repository secrets.

---

## 3. Configuring GitHub Repository Secrets

Configure the 4 required secrets on your repository using the GitHub CLI:

```bash
# Export the keystore binary as a single-line base64 string
B64_KEYSTORE=$(base64 -w 0 isohedron-release.jks)

# Upload secrets to GitHub Actions
gh secret set ANDROID_KEYSTORE_BASE64 --body "$B64_KEYSTORE"
gh secret set ANDROID_KEY_ALIAS --body "isohedron"
gh secret set ANDROID_KEY_PASSWORD --body "<your-key-password>"
gh secret set ANDROID_KEYSTORE_PASSWORD --body "<your-keystore-password>"
```

### Verifying Secrets
```bash
gh secret list
```

---

## 4. How the CI/CD Signing Pipeline Works

Inside `.github/workflows/nightly.yml`:
1. **Decode:** The workflow decodes `ANDROID_KEYSTORE_BASE64` to `release.jks`.
2. **Ephemeral Fallback:** If secrets are absent (e.g. on forks), an ephemeral key is generated so CI builds remain verifiable.
3. **Sign:** The release APK is cryptographically signed using Android SDK's `apksigner`:
   ```bash
   apksigner sign \
     --ks release.jks \
     --ks-key-alias "$KEY_ALIAS" \
     --ks-pass "pass:$KEYSTORE_PASS" \
     --key-pass "pass:$KEY_PASS" \
     --out Isohedron-nightly-signed.apk \
     build/app/outputs/apk/release/app-unsigned.apk
   ```
4. **Verification:** The signature is verified on the runner:
   ```bash
   apksigner verify Isohedron-nightly-signed.apk
   ```
5. **Publish:** The signed artifact is attached to the rolling `nightly` release.

---

## 5. Key Rotation

If credentials ever need rotation:
1. Generate a new keystore using `scripts/generate-keystore.sh`.
2. Update the repository secrets with `gh secret set`.
3. The next nightly run will automatically sign using the new credentials.
