# Android Release Signing & Security Guide

This document details how **Isohedron** signs Android release builds, maintains cryptographic signing consistency, and safeguards private key credentials.

---

## 1. Overview & Security Principles

* **Signing Consistency:** Android enforces that application updates must be signed with the exact same certificate key. If the signing key changes, Android blocks app updates with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. The official pipeline enforces that official builds are strictly signed by the authoritative release keystore (`ovrrup/isohedron` halts if the secret is missing, preventing inconsistent disposable keys).
* **Git Cleanliness:** Private keystores (`*.jks`, `*.keystore`, `*.p12`, `*.pkcs12`, `*.pem`, `*.key`, `*.pfx`) and `key.properties` are strictly blocked by `.gitignore`. They must **never** be committed to the public repository.
* **Process Isolation & Immediate Shredding:** Release signing is automated inside GitHub Actions via `apksigner`. Passwords are provided via step-scoped environment variables (never written to disk or `$GITHUB_ENV`). The decoded keystore on the runner is trapped and shredded immediately upon step exit (`trap 'rm -f release.jks' EXIT`).
* **Format:** Keys are generated as standard **PKCS#12** keystores (RSA 2048-bit, 10,000 days validity), compatible with both modern Java/Android build-tools and OpenSSL.

---

## 2. Authoritative Release Credentials

* **Key Alias:** `isohedron`
* **Validity:** 10,000 days (~27 years)
* **Certificate SHA-256 Fingerprint:**
  ```text
  23:6F:78:6A:EF:87:CC:60:27:0A:FC:AF:85:76:12:6E:F8:65:C5:44:CD:6F:69:74:7A:35:48:F5:B0:81:88:80
  ```
  Every official release published on GitHub Actions prints this fingerprint in its changelog notes so users can verify cryptographic authenticity.

---

## 3. Backing Up the Master Keystore

Because Android update compatibility depends on this key, the master `isohedron-release.jks` should be backed up securely in an encrypted vault (such as Bitwarden, 1Password, or KeePass):

1. Locate the master keystore file (e.g. `~/.isohedron-secrets/isohedron-release.jks`).
2. Attach `isohedron-release.jks` as a secure file attachment in your vault entry.
3. Record the Key Alias (`isohedron`) and passwords alongside the attachment.

---

## 4. Generating New Signing Credentials

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

## 5. Configuring GitHub Repository Secrets

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

## 6. How the CI/CD Signing Pipeline Works

Inside `.github/workflows/nightly.yml`:
1. **Consistency Gate:** Checks for `ANDROID_KEYSTORE_BASE64`. On `ovrrup/isohedron`, if this secret is missing, the job aborts immediately with an error rather than signing with an ephemeral key.
2. **Ephemeral Fallback for Forks:** For non-official fork repositories, an ephemeral key is generated so fork CI workflows pass without needing private secrets.
3. **Trap Cleanup:** Sets `trap 'rm -f release.jks' EXIT` ensuring the keystore file is destroyed immediately after signing.
4. **Sign:** The release APK is cryptographically signed using Android SDK's `apksigner`:
   ```bash
   apksigner sign \
     --ks release.jks \
     --ks-key-alias "$KEY_ALIAS" \
     --ks-pass "pass:$KEYSTORE_PASS" \
     --key-pass "pass:$KEY_PASS" \
     --min-sdk-version 21 \
     --out Isohedron-nightly-signed.apk \
     build/app/outputs/apk/release/app-unsigned.apk
   ```
5. **Verification & Audit:** The signature is verified and the certificate SHA-256 fingerprint is extracted and written into `changelog.md`.
6. **Publish:** The signed artifact is published to the rolling `nightly` pre-release.

---

## 7. Key Rotation

If credentials ever need rotation:
1. Generate a new keystore using `scripts/generate-keystore.sh`.
2. Update the repository secrets with `gh secret set`.
3. The next nightly run will automatically sign using the new credentials.
