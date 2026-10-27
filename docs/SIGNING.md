# Android Release Signing & Security Architecture

This document outlines the security architecture used by **Isohedron** to sign Android release artifacts while keeping signing secrets private and protected.

---

## 1. Security Architecture Principles

* **Release Keystore Confidentiality:** The authoritative release signing keystore is stored exclusively in encrypted, access-controlled repository secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Private keys are never committed to the git repository.
* **Ephemeral Process Isolation:** During automated CI builds on GitHub Actions, the keystore is decoded into a short-lived temporary file. A POSIX shell `trap 'rm -f release.jks' EXIT` guarantees the keystore is immediately destroyed upon step completion or failure.
* **Environment Variable Hygiene:** Signing passwords are provided strictly via step-scoped environment variables. Passwords are never written to disk, job logs, or persisted runner state files.
* **Strict Git Tracking Controls:** `.gitignore` enforces strict exclusion of all keystore formats (`*.jks`, `*.keystore`, `*.p12`, `*.pkcs12`, `*.pem`, `*.key`, `*.pfx`) and credential property files (`key.properties`).
* **Cryptographic Signing via apksigner:** All official release builds are cryptographically signed using Android SDK's `apksigner` with APK Signature Scheme v2/v3 support.

---

## 2. GitHub Actions Automated Signing Flow

The automated release workflow (`.github/workflows/nightly.yml`) follows these steps:

1. **Flutter APK Compilation:** Builds release APK using `flutter build apk --release`.
2. **Secret Decryption:** Decodes `ANDROID_KEYSTORE_BASE64` into a temporary `release.jks`.
3. **Apksigner Execution:** Signs the release APK with the configured key alias and password.
4. **Immediate Shredding:** Trapped cleanup routine removes `release.jks` from the workspace.
5. **Verification:** Inspects the signed APK with `apksigner verify` to ensure structural integrity before publishing.
