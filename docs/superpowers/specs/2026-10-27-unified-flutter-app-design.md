# Unified Flutter App & Android Release Design

## 1. Intent & Problem Statement

The previous release pipeline packaged an empty 8 KiB archive using `aapt package` containing only a manifest without compiled Android bytecode (`classes.dex`), Flutter engine binaries (`libflutter.so`), or compiled Dart AOT code (`libapp.so`). When installed on an Android device, the operating system rejected the package as corrupted and invalid.

This design converts Isohedron into a unified root Flutter project, providing the complete Android Gradle scaffolding, modern Material 3 user interface widgets wired to the existing core domain/storage services, and an automated GitHub Actions build pipeline that produces and cryptographically signs a genuine, installable Flutter Android APK.

---

## 2. Approaches Considered

### Approach 1: Monorepo — `core/` (Pure Dart) + `app/` (Flutter Android App)
* **Description:** Separate pure Dart engine from the Flutter UI in two packages.
* **Trade-offs:** Kept `dart test` runnable in raw Termux without Flutter SDK, but added folder indirection and non-standard project layout.

### Approach 2: Unified Root Flutter Project (Chosen by User)
* **Description:** Root directory is a standard Flutter project with `pubspec.yaml` referencing `sdk: flutter`. Android Gradle scaffolding lives in `android/` at the root, and Flutter UI widgets live in `lib/`.
* **Trade-offs:** Industry-standard Flutter repository layout recognizable by all Flutter tooling and IDEs. All dependency resolution, linting, testing, and compilation are driven through GitHub Actions CI (`flutter test`, `flutter build apk --release`).
* **Why Chosen:** Cleanest architecture, zero folder indirection, and standard compatibility with Flutter ecosystem tooling.

---

## 3. Goals, Non-Goals & Anti-Goals

### Goals
* Produce a genuine, fully installable Android APK (`Isohedron-nightly-signed.apk`, ~15–25 MB) containing `classes.dex`, `libflutter.so`, `libapp.so`, and assets.
* Implement complete Android Gradle scaffolding compatible with Flutter 3.x and Android Gradle Plugin 8.x (Java 17, target SDK 34, min SDK 21).
* Build a functional, minimal Material 3 UI connecting the existing models (`TaskItem`, `TaskList`, `TaskFilter`) and services (`StorageService`, `NotificationService`, `GoogleTasksService`).
* Preserve the reflection prompt loop (asking reasons when dropping/cancelling tasks) and planned time alarm picker dialogs.
* Retain cryptographic signing consistency via `apksigner sign` using the authoritative repository release credentials.

### Non-Goals
* Local native APK compilation inside Termux on device (delegated to GitHub Actions runners).
* Complex multi-screen navigation (remains a focused, minimal single-screen task manager with modal sheets/dialogs).

### Anti-Goals
* Never produce dummy or synthetic packages. The output artifact must be a real Flutter release build verified by the Android OS.

---

## 4. Architecture & Component Design

### A. Android Scaffolding (`android/`)
* **`android/settings.gradle`**: Modern Flutter plugin loader applying `dev.flutter.flutter-plugin-loader`, `com.android.application`, and `org.jetbrains.kotlin.android`.
* **`android/build.gradle`**: Root Gradle build script defining repository mirrors (Google, MavenCentral).
* **`android/app/build.gradle`**: Application Gradle config declaring `namespace "com.ovrrup.isohedron"`, `minSdk 21`, `targetSdk 34`, Java 17 compile options, `coreLibraryDesugaring` for notification time APIs, and Flutter Gradle plugin.
* **`android/app/src/main/AndroidManifest.xml`**: Defines `MainActivity` extending `io.flutter.embedding.android.FlutterActivity` with `LAUNCHER` intent filter, normal/launch theme metadata, and notification permissions (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`).
* **`android/app/src/main/kotlin/com/ovrrup/isohedron/MainActivity.kt`**: Standard Kotlin entrypoint subclassing `FlutterActivity`.
* **Gradle Wrapper**: `gradle/wrapper/gradle-wrapper.properties` targeting Gradle 8.3+.

### B. User Interface & Services (`lib/`)
* **`lib/main.dart`**: Entrypoint initializing `path_provider` local directory storage, real `NotificationService` (wrapping `flutter_local_notifications`), and local-first `GoogleTasksService.mock()`, running `IsohedronApp`.
* **Google Tasks Integration**: Local-first by default with in-app Mock sync toggle ("demo@google.com") enabling immediate offline multi-list testing without external Google Cloud Console configuration.
* **Scheduled Alarms**: Real Android OS notifications via `flutter_local_notifications` with exact alarms and notification channels, alerting the user even when the application is backgrounded or closed.
* **Theme**: Minimal Material 3 styling (light/dark mode aware, clean typography, unobtrusive accents).
* **Screens & Widgets**:
  * `HomeScreen`: Top AppBar with Task List Switcher dropdown ("Personal", "Work", Google Tasks with cloud badge) and Google sync button.
  * Search bar & Status Filter segmented tabs (`All`, `Today`, `Planned`, `Completed`, `Cancelled`).
  * `TaskListView`: Dismissible/interactive task tiles with completion checkboxes, planned alarm chips, and cancellation reason badges.
  * `CancelReasonDialog`: Modal prompt presenting preset reflection chips ("Ran out of time", "Deprioritized", "Waiting on something", "No longer needed") plus custom reflection input.
  * `PlanTaskDialog`: Modal date/time scheduler with quick chips (+1 Hour, Tonight at 8 PM, Tomorrow Morning at 9 AM).
  * `FloatingActionButton`: Quick task creation.

### C. CI/CD & Nightly Release Pipeline
* **GitHub Actions (`.github/workflows/nightly.yml` and `build.yml`)**:
  1. `actions/setup-java@v4` with Java 17.
  2. `subosito/flutter-action@v2` with `channel: 'stable'` and cache enabled.
  3. `flutter pub get`.
  4. `flutter analyze --fatal-infos`.
  5. `flutter test`.
  6. `flutter build apk --release --no-tree-shake-icons`.
  7. Decode release keystore from `secrets.ANDROID_KEYSTORE_BASE64` with trap removal.
  8. `apksigner sign --min-sdk-version 21` on `build/app/outputs/flutter-apk/app-release.apk`.
  9. `apksigner verify` and extract certificate SHA-256 fingerprint (`236f786a...`).
  10. Rolling release: delete previous nightly and publish new rolling pre-release with `Isohedron-nightly-signed.apk`.
