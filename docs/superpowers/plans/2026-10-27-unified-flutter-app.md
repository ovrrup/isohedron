# Unified Flutter Application & Real Android Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, unified Flutter Android application for Isohedron with real Google Tasks OAuth synchronization, system-level scheduled notifications, Material 3 UI, and an automated GitHub Actions CI pipeline that builds, signs, and publishes a genuine, installable APK.

**Architecture:** The project root is converted into a standard Flutter application with full Android Gradle 8.3+ scaffolding. Domain models and local JSON persistence are connected to real Android system notifications via `flutter_local_notifications` and two-way Google Tasks synchronization via `google_sign_in` and `googleapis.tasks.v1`. CI compiles the real release APK via `flutter build apk --release` and cryptographically signs it using `apksigner`.

**Tech Stack:** Flutter 3.24+ / Dart 3.5+, Android Gradle Plugin 8.3+, Java 17, `google_sign_in`, `googleapis`, `flutter_local_notifications`, `path_provider`, `intl`, OpenSSL PKCS#12, `apksigner`.

**Spec:** [`docs/superpowers/specs/2026-10-27-unified-flutter-app-design.md`](file:///data/data/com.termux/files/home/iso/docs/superpowers/specs/2026-10-27-unified-flutter-app-design.md)

## Global Constraints

* Target Android API: `compileSdk = 34`, `minSdk = 21`, `targetSdk = 34`.
* Java Version: Java 17 (`sourceCompatibility` & `targetCompatibility`).
* Keystore Alias: `isohedron`.
* Release Signing: Managed via GitHub Repository Secrets (`ANDROID_KEYSTORE_BASE64`).
* Output APK Filename: `Isohedron-nightly-signed.apk`.
* Zero-clutter rolling nightly: Only 1 rolling `nightly` tag/release on GitHub.

## Review Focus

1. Missing `classes.dex` or corrupt APK archive: Must compile real Flutter AOT bytecode and native libs (`flutter build apk --release`), producing an APK > 10 MB.
2. Unauthenticated Google Tasks calls: If Google Sign-In is cancelled or not yet performed, app must operate 100% offline using local storage without crashing or showing unhandled exceptions.
3. Android 13+ Notification Permission: When scheduling alarms on Android 13+ (API 33+), runtime permission `POST_NOTIFICATIONS` must be requested before scheduling.
4. Desugaring on Android minSdk 21: `coreLibraryDesugaring` must be enabled in Gradle so modern `java.time` APIs used by `flutter_local_notifications` run on Android 21-25 without runtime crashes.
5. In-Note Metadata Roundtrip: When syncing tasks to and from Google Tasks, `[Planned: <iso>]` and `[Cancelled: <reason> on <date>]` must be parsed from and written back into Google Tasks note bodies accurately.

---

### Task 1: Flutter Project Manifest & Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `analysis_options.yaml`

**Interfaces:**
- Produces: Complete Flutter project dependencies including `flutter`, `google_sign_in`, `googleapis`, `flutter_local_notifications`, `path_provider`, `intl`, and `http`.

- [ ] **Step 1: Write `pubspec.yaml` with Flutter SDK and required plugins**

Configure `pubspec.yaml`:
```yaml
name: isohedron
description: "Minimal task manager with Google Tasks integration and reflection loop."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  intl: ^0.19.0
  googleapis: ^13.2.0
  http: ^1.2.0
  google_sign_in: ^6.2.1
  flutter_local_notifications: ^17.2.1
  path_provider: ^2.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 2: Update `analysis_options.yaml`**

Include standard `package:flutter_lints/flutter.yaml`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml analysis_options.yaml
git commit -m "chore: configure Flutter manifest and dependencies in pubspec.yaml"
```

---

### Task 2: Android Gradle Scaffolding & Native Manifest

**Files:**
- Create: `android/build.gradle`
- Create: `android/settings.gradle`
- Create: `android/app/build.gradle`
- Create: `android/gradle/wrapper/gradle-wrapper.properties`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/kotlin/com/ovrrup/isohedron/MainActivity.kt`
- Create: `android/app/src/main/res/values/styles.xml`
- Create: `android/app/src/main/res/drawable/launch_background.xml`

**Interfaces:**
- Produces: Complete Android build harness compatible with Gradle 8.3+, Android Gradle Plugin 8.3+, Java 17 desugaring, and Android 14 (API 34).

- [ ] **Step 1: Create `android/settings.gradle`**

Configure plugin management, Flutter tools loader, and repository mirrors:
```groovy
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.3.2" apply false
    id "org.jetbrains.kotlin.android" version "1.9.23" apply false
}

include ":app"
```

- [ ] **Step 2: Create `android/build.gradle`**

Root project Gradle script:
```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = "../build"
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
```

- [ ] **Step 3: Create `android/app/build.gradle`**

Configure application settings, Java 17 desugaring for `flutter_local_notifications`, namespace, and release build types:
```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace = "com.ovrrup.isohedron"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        coreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.ovrrup.isohedron"
        minSdk = 21
        targetSdk = 34
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

- [ ] **Step 4: Create `android/gradle/wrapper/gradle-wrapper.properties`**

Target Gradle 8.3:
```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.3-all.zip
```

- [ ] **Step 5: Create `android/app/src/main/AndroidManifest.xml`**

Configure `MainActivity`, permissions for notifications and alarms, and launcher metadata:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.ovrrup.isohedron">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />

    <application
        android:label="Isohedron"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

- [ ] **Step 6: Create `MainActivity.kt`, `styles.xml`, and `launch_background.xml`**

Write standard Kotlin `MainActivity.kt` and basic launch themes.

- [ ] **Step 7: Commit**

```bash
git add android/
git commit -m "feat(android): add complete Flutter Android Gradle scaffolding and manifest"
```

---

### Task 3: Real Google Tasks OAuth Integration

**Files:**
- Modify: `lib/services/google_tasks_service.dart`
- Test: `test/services/google_tasks_service_test.dart`

**Interfaces:**
- Produces: `GoogleTasksService.live()` using `GoogleSignIn(scopes: ['https://www.googleapis.com/auth/tasks'])` with authenticated `http.Client` bridging Google Tasks API v1 (`TasksApi`).
- Preserves: `GoogleTasksService.mock()` for offline testing.

- [ ] **Step 1: Implement `GoogleAuthClient` in `lib/services/google_tasks_service.dart`**

Create authenticated HTTP client delegating requests with Google Auth headers:
```dart
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
```

- [ ] **Step 2: Implement `LiveGoogleTasksClient` using `google_sign_in` and `TasksApi`**

Implement sign in, sign out, list querying, task insertion, update, and remote reconciliation with live `TasksApi`.

- [ ] **Step 3: Update `GoogleTasksService` factory to support live and mock modes**

Allow runtime sign in / sign out toggle from the UI while keeping offline mock client for automated tests.

- [ ] **Step 4: Verify test suite**

Run unit tests confirming mock and live contracts remain intact.

- [ ] **Step 5: Commit**

```bash
git add lib/services/google_tasks_service.dart test/services/google_tasks_service_test.dart
git commit -m "feat(google_tasks): implement live Google Tasks OAuth2 client with TasksApi"
```

---

### Task 4: Real Android System Notification Service

**Files:**
- Modify: `lib/services/notification_service.dart`
- Test: `test/services/notification_service_test.dart`

**Interfaces:**
- Produces: `NotificationService` supporting `flutter_local_notifications` for real Android scheduled alarms, with fallback to in-memory adapter for headless test environments.

- [ ] **Step 1: Implement `FlutterLocalNotificationAdapter`**

Wrap `FlutterLocalNotificationsPlugin`:
- Initialize Android notification channel (`isohedron_reminders`, "Task Reminders", importance: `Importance.high`).
- Handle Android 13+ permission request via `plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()`.
- Schedule alarm using `zonedSchedule` or `schedule` with `AndroidScheduleMode.exactAllowWhileIdle`.

- [ ] **Step 2: Maintain `MockNotificationAdapter` for headless tests**

Keep existing mock adapter so pure headless CI/testing does not crash when native plugin channels are absent.

- [ ] **Step 3: Commit**

```bash
git add lib/services/notification_service.dart test/services/notification_service_test.dart
git commit -m "feat(notifications): add flutter_local_notifications adapter for Android system alarms"
```

---

### Task 5: Material 3 User Interface & Widgets

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/ui/home_screen.dart`
- Modify: `lib/ui/cancel_reason_dialog.dart`
- Modify: `lib/ui/plan_task_dialog.dart`
- Modify: `lib/ui/task_list_switcher.dart`

**Interfaces:**
- Produces: Full Material 3 Flutter application with interactive UI.

- [ ] **Step 1: Implement `IsohedronApp` in `lib/main.dart`**

Initialize `path_provider` application documents directory for storage persistence, initialize `NotificationService`, and mount `MaterialApp` with Material 3 styling:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docsDir = await getApplicationDocumentsDirectory();
  final storageFile = File('${docsDir.path}/isohedron_tasks.json');
  // ...
  runApp(const IsohedronApp());
}
```

- [ ] **Step 2: Implement `HomeScreen` Flutter Widget in `lib/ui/home_screen.dart`**

Build:
- Top `AppBar` with `TaskListSwitcher` popup, Google sign in/sync icon button, and search toggle.
- Segmented button or `TabBar` for `TaskFilter` (`All`, `Today`, `Planned`, `Completed`, `Cancelled`).
- `ListView.builder` rendering `TaskItemTile` with checkbox, planned time chip, cancellation reason pill, and swipe-to-cancel action.
- `FloatingActionButton` to create tasks with title, notes, and plan picker.

- [ ] **Step 3: Implement `CancelReasonDialog` Widget**

Material dialog displaying preset chips ("Ran out of time", "Deprioritized", "Waiting on something", "No longer needed"), custom text field, and confirm button.

- [ ] **Step 4: Implement `PlanTaskDialog` Widget**

Date & Time picker with quick shortcut buttons (+1 Hour, Tonight at 8 PM, Tomorrow Morning at 9 AM).

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/ui/
git commit -m "feat(ui): implement Material 3 task manager widgets and dialogs"
```

---

### Task 6: GitHub Actions Real Flutter APK Build & Nightly Signing

**Files:**
- Modify: `.github/workflows/build.yml`
- Modify: `.github/workflows/nightly.yml`
- Modify: `test/scripts/workflow_syntax_test.sh`

**Interfaces:**
- Produces: Automated multi-platform CI and rolling nightly release pipeline compiling genuine Flutter Android APK (`flutter build apk --release`), signing with `apksigner sign`, and publishing `Isohedron-nightly-signed.apk` (~15–25 MB).

- [ ] **Step 1: Update `.github/workflows/build.yml`**

Install Flutter via `subosito/flutter-action@v2`, run `flutter pub get`, `flutter analyze --fatal-infos`, `flutter test`, and `flutter build apk --release --no-tree-shake-icons`.

- [ ] **Step 2: Update `.github/workflows/nightly.yml`**

Replace dummy `aapt package` with real Flutter compilation:
```yaml
      - name: Build Android Release APK
        run: flutter build apk --release --no-tree-shake-icons

      - name: Sign & Verify Android Release APK
        id: sign_apk
        env:
          KEYSTORE_B64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS || 'isohedron' }}
          KEY_PASS: ${{ secrets.ANDROID_KEY_PASSWORD }}
          KEYSTORE_PASS: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
        run: |
          UNSIGNED_APK="build/app/outputs/flutter-apk/app-release.apk"
          SIGNED_APK="Isohedron-nightly-signed.apk"
          # ...
          "$APKSIGNER" sign \
            --ks release.jks \
            --ks-key-alias "$ACTUAL_ALIAS" \
            --ks-pass "pass:$ACTUAL_STORE_PASS" \
            --key-pass "pass:$ACTUAL_KEY_PASS" \
            --min-sdk-version 21 \
            --out "$SIGNED_APK" \
            "$UNSIGNED_APK"
```

- [ ] **Step 3: Update `test/scripts/workflow_syntax_test.sh`**

Assert that `flutter build apk --release` and `flutter-apk/app-release.apk` are present in `nightly.yml`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ test/scripts/workflow_syntax_test.sh
git commit -m "ci: compile and sign real Flutter Android APK in nightly workflow"
```
