# Design: Nightly Release Channel Workflow

**Date:** 2026-10-27  
**Status:** Pending User Approval  
**Scope:** Small Feature (CI/CD Workflow)  
**Target:** `.github/workflows/nightly.yml`  

---

## 1. Intent and Why
Provide an automated, professional nightly release channel for Isohedron that compiles and publishes nightly pre-releases to GitHub Releases. The system must operate without cluttering the repository with dozens of obsolete releases.

---

## 2. Goals, Non-Goals, and Anti-Goals

### Goals
* **Automated Daily Trigger:** Executes on a daily schedule (e.g. 02:00 UTC) with manual trigger (`workflow_dispatch`) support.
* **Commit-Aware:** Checks whether `main` has new commits since the last nightly release. Skips silently if no changes have landed.
* **Quality Gate:** Runs full static analysis (`dart analyze --fatal-infos`) and the test suite (`dart test`) before packaging.
* **Zero-Clutter Rolling Release:** Automatically deletes any existing `nightly` release and tag before publishing the new build, ensuring exactly one clean pre-release exists on GitHub Releases at any time.
* **Permanent Download Link:** Provides a stable, unchanging asset URL (`.../releases/download/nightly/...`) for users and testers.
* **Automated Changelog:** Auto-generates release notes highlighting recent commits included in the build.

### Non-Goals
* Archiving historical nightly builds indefinitely (user explicitly requested replacement of old nightlies).
* Releasing on pull requests or feature branches (strictly tracks `main`).

### Anti-Goals
* No untrusted third-party GitHub Marketplace actions for release management; rely solely on GitHub's built-in `gh` CLI.

---

## 3. Constraints
* Must use GitHub Actions workflows.
* Keep dependency footprint minimal (zero unnecessary marketplace actions).
* Safe permissions (`contents: write` required for creating releases and pushing tags).

---

## 4. Approaches Considered

### Approach A: Single Rolling `nightly` Pre-Release via Native `gh` CLI (Selected)
* Uses `gh release delete nightly --yes --cleanup-tag` followed by `gh release create nightly --prerelease --title "Isohedron Nightly (<date>)" --generate-notes`.
* **Tradeoffs:** Zero clutter, predictable download URL, 100% native tooling.
* **Decision:** Selected per user request.

### Approach B: Dated Tags with Automated Pruning Script (`nightly-YYYYMMDD`)
* Creates dated tags and prunes older ones via script.
* **Tradeoffs:** Fragmented URLs requiring API lookups; more moving parts.
* **Decision:** Dropped in favor of the cleaner single rolling tag.

---

## 5. Implementation Specification

### Workflow File: `.github/workflows/nightly.yml`
* **Trigger:**
  ```yaml
  on:
    schedule:
      - cron: '0 2 * * *' # Every night at 02:00 UTC
    workflow_dispatch:     # Allows manual trigger
  ```
* **Permissions:**
  ```yaml
  permissions:
    contents: write
  ```
* **Steps:**
  1. `actions/checkout@v4` with `fetch-depth: 0` (full history for changelog and commit diffs).
  2. Check for new commits on `main` since `nightly` tag:
     * If `nightly` tag exists and points to `HEAD`, exit with notice ("No new commits since last nightly. Skipping.").
  3. Set up Dart / Flutter environment.
  4. Run `dart pub get`, `dart analyze --fatal-infos`, and `dart test`.
  5. Build release artifacts and package bundle.
  6. Delete existing `nightly` release and tag via `gh release delete nightly --yes --cleanup-tag || true`.
  7. Publish fresh `nightly` pre-release via `gh release create nightly <artifacts> --prerelease --title "Isohedron Nightly - $(date +'%Y-%m-%d')" --generate-notes`.

---

## 6. What's Left to the Builder
* Release note template formatting and artifact file naming conventions.
