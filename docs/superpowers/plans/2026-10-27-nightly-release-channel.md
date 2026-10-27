# Nightly Release Channel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an automated, clutter-free nightly release channel via GitHub Actions that generates Android signing credentials, signs the release APK, and publishes a single rolling `nightly` pre-release.

**Architecture:** A scheduled and dispatchable GitHub Actions workflow (`.github/workflows/nightly.yml`) checks for commit differences on `main`. If new commits exist, it validates tests, builds and signs the Android APK with `apksigner` using credentials decoded from GitHub Secrets, removes the previous `nightly` tag and release, and publishes the fresh build with automated release notes.

**Tech Stack:** GitHub Actions, GitHub CLI (`gh`), `apksigner`, OpenSSL / PKCS#12 keystore, Dart SDK.

**Spec:** `docs/superpowers/specs/2026-10-27-nightly-releases-design.md`

## Global Constraints

* Target: Android APK signing and GitHub Releases channel.
* Security: Private keystores (`*.jks`, `*.keystore`) must never be tracked in git; `.gitignore` must strictly block them.
* Zero clutter: Only one rolling `nightly` pre-release can exist on GitHub Releases at any time.
* Standard tooling: Use official GitHub CLI (`gh`) and Android build-tools `apksigner`.

## Review Focus

1. **Missing GitHub Secrets fallback:** If repository secrets are not configured, workflow must generate an ephemeral build key so nightly CI does not break.
2. **No-op nights:** If no commits have landed since the previous nightly build, workflow must exit early with a clean notice without modifying releases.
3. **Keystore git leak prevention:** Verify `.gitignore` prevents private keys from ever being staged or committed.
4. **Clean release replacement:** `gh release delete nightly --yes --cleanup-tag` must handle cases where no prior nightly exists without failing.
5. **APK signature verification:** The workflow must run `apksigner verify` to ensure the release APK is properly signed with v2/v3 signatures.

---

### Task 1: Signing Credentials Generation & Security Configuration

**Files:**
- Modify: `.gitignore`
- Create: `scripts/generate-keystore.sh`
- Test: `test/scripts/keystore_test.sh`

**Interfaces:**
- Produces: Keystore generation script, git safety rules, and validation test verifying PKCS#12 keystore creation and base64 export.

- [ ] **Step 1: Write test for keystore generation script**
  Test that `scripts/generate-keystore.sh` creates a valid PKCS#12 keystore file and generates a non-empty base64 string.

- [ ] **Step 2: Run test to verify it fails**
  Run: `bash test/scripts/keystore_test.sh`
  Expected: FAIL (script not found)

- [ ] **Step 3: Update `.gitignore` for keystores and signing properties**
  Add `*.jks`, `*.keystore`, `*.p12`, and `key.properties`.

- [ ] **Step 4: Implement `scripts/generate-keystore.sh`**
  Use `openssl` to generate RSA 2048-bit key and self-signed certificate, export to PKCS#12 `.jks` file with specified alias and password, and output instructions for `gh secret set`.

- [ ] **Step 5: Run test to verify it passes**
  Run: `bash test/scripts/keystore_test.sh`
  Expected: PASS

- [ ] **Step 6: Commit**
  ```bash
  git add .gitignore scripts/generate-keystore.sh test/scripts/keystore_test.sh
  git commit -m "feat(signing): add keystore generation script and security ignore rules"
  ```

---

### Task 2: Nightly Release GitHub Actions Workflow

**Files:**
- Create: `.github/workflows/nightly.yml`
- Test: `test/scripts/workflow_syntax_test.sh`

**Interfaces:**
- Consumes: Task 1 secrets schema, project test suite
- Produces: `.github/workflows/nightly.yml` with commit check, test gates, signing, and rolling release replacement.

- [ ] **Step 1: Write test for workflow configuration and bash commands**
  Validate yaml structure, triggers (`schedule` + `workflow_dispatch`), permissions (`contents: write`), and syntax of inline scripts.

- [ ] **Step 2: Run test to verify it fails**
  Run: `bash test/scripts/workflow_syntax_test.sh`
  Expected: FAIL

- [ ] **Step 3: Implement `.github/workflows/nightly.yml`**
  Implement:
  * Schedule `0 2 * * *` and `workflow_dispatch`.
  * Commit-check step comparing `origin/main` against `refs/tags/nightly`.
  * Test execution step (`dart test`, `dart analyze`).
  * Keystore decoding from `ANDROID_KEYSTORE_BASE64` with ephemeral fallback.
  * APK build and `apksigner` signing + verification step.
  * `gh release delete nightly --yes --cleanup-tag || true` and `gh release create nightly ...`.

- [ ] **Step 4: Run test to verify it passes**
  Run: `bash test/scripts/workflow_syntax_test.sh`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add .github/workflows/nightly.yml test/scripts/workflow_syntax_test.sh
  git commit -m "feat(ci): implement nightly rolling release workflow with APK signing"
  ```

---

### Task 3: Documentation & GitHub Secrets Setup

**Files:**
- Create: `docs/SIGNING.md`
- Modify: `README.md`
- Test: Verify links and run `dart test` & `dart analyze`

**Interfaces:**
- Produces: Comprehensive guide for configuring GitHub Secrets, rotating keys, and downloading nightly builds.

- [ ] **Step 1: Create `docs/SIGNING.md`**
  Detail how to generate credentials using `scripts/generate-keystore.sh`, how to set secrets via `gh secret set`, and how the signing pipeline operates in CI.

- [ ] **Step 2: Update `README.md` with Nightly Channel information**
  Add Nightly Channel badge, permanent download URL (`https://github.com/ovrrup/isohedron/releases/tag/nightly`), and signing details.

- [ ] **Step 3: Run full verification suite**
  Run: `dart test && dart analyze`
  Expected: ALL PASS

- [ ] **Step 4: Commit**
  ```bash
  git add docs/SIGNING.md README.md
  git commit -m "docs: add signing and nightly release channel documentation"
  ```
