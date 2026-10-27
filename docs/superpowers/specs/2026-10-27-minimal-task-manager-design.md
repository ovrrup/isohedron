# Design: Minimal Task Manager with Google Tasks & Reflection (iOS & Android)

**Date:** 2026-10-27  
**Status:** Pending User Approval  
**Platforms:** iOS, Android  
**Stack:** Flutter (Dart), Google Tasks REST API, GitHub Actions CI  

---

## 1. Intent and Why

Most to-do apps suffer from two major drop-off points:
1. **Cold start friction:** Setting up tasks from scratch in a new app feels tedious.
2. **Lack of follow-through & accountability:** Tasks get scheduled or forgotten, and when skipped, there is zero reflection on *why* they were missed.

This app solves both:
* **The Hook:** Direct integration with **Google Tasks**, allowing users to immediately bring in their existing to-do lists without configuring a custom cloud backend.
* **The Core Loop:** Users plan a specific time for their tasks. When the time comes, the app delivers a scheduled local notification.
* **The Reflection Loop:** When a task is completed, it syncs as done. If the user marks it as cancelled / not done, the app prompts for the reason and records it directly into the task's notes/history, providing actionable insight into why tasks fail.

---

## 2. Goals, Non-Goals, and Anti-Goals

### Goals
* **Cross-Platform:** Single codebase running natively on both iOS and Android.
* **Lean Dependency Footprint:** Zero unnecessary third-party libraries; rely on Flutter core and official/standard packages only (`googleapis`, `google_sign_in`, `flutter_local_notifications`, `shared_preferences`).
* **Google Tasks Sync & Multi-List Support:** Fetch user task lists with an integrated list switcher dropdown, fetch tasks for the selected list, mark completed, create tasks, and sync cancellation reasons back into task notes.
* **Local Offline Support:** Cache tasks and task lists locally so the app opens instantly and works offline.
* **Scheduled Alarms / Notifications:** Trigger local OS notifications at the planned time even if the app is backgrounded.
* **Reflection Prompt:** Quick modal/sheet prompt asking "Why wasn't this done?" when a task is cancelled, appending `[Cancelled: <reason>]` to notes.
* **Cloud-First CI/CD:** GitHub Actions workflows that automatically build the Android APK and test iOS compilation on push, keeping local development clean and lightweight.

### Non-Goals
* No custom multi-tenant server backend (no Node/Postgres/Firebase auth servers required).
* No bloated collaboration/team kanban boards or complex project gantt charts.
* No continuous background battery-draining polling (sync on launch, pull-to-refresh, or action trigger).

### Anti-Goals
* **No UI/Library Bloat:** Do not pull in heavy UI component kits (e.g. no huge design system packages); use standard Flutter Material 3 / Cupertino styling.
* **No heavy local build requirement:** The codebase should be fully buildable and verifiable via GitHub Actions CI without needing heavy local native compilers on mobile dev environments.

---

## 3. Constraints

1. **Target Platforms:** iOS and Android.
2. **Minimal Dependencies:** Use only essential packages required for Google OAuth, Google Tasks API, notifications, and local key-value caching.
3. **CI/CD Build System:** GitHub Actions must be the primary pipeline for building artifacts (APK for Android, project build for iOS).
4. **Offline Capability:** Core task listing and reason recording must function without an active internet connection, queueing syncs when back online.

---

## 4. Approaches Considered

### Approach A: Flutter with Minimal Official Plugins (Selected)
* **Architecture:** Clean Flutter application utilizing `googleapis` / `google_sign_in` for Google Tasks, `flutter_local_notifications` for alarms, and `shared_preferences` for local persistence.
* **CI/CD:** GitHub Actions with `subosito/flutter-action` on `ubuntu-latest` (Android APK) and `macos-latest` (iOS build).
* **Tradeoffs:** High native performance, reliable local background notifications across both mobile OSes, minimal dependency footprint, and standard tooling.
* **Decision:** Chosen because it provides reliable native notifications and seamless Google API integration while maintaining a minimal, robust architecture.

### Approach B: Lean Web Core + Capacitor Wrapper
* **Architecture:** Vanilla TypeScript/HTML single-page app wrapped in Capacitor for native shells.
* **Tradeoffs:** Smaller local source tree, but native background alarm scheduling and OAuth redirect handling in Capacitor require extra bridge maintenance and can be inconsistent on iOS.
* **Decision:** Dropped in favor of Flutter's native-first notification reliability.

### Approach C: React Native / Expo
* **Architecture:** React Native with minimal Expo modules.
* **Tradeoffs:** Deep `node_modules` dependency graph, more complex GitHub Actions CI setup compared to Flutter's lightweight single-step action.
* **Decision:** Dropped due to heavier dependency footprint.

---

## 5. Architectural Specification

### 5.1 Project Structure
```
.
├── .github/
│   └── workflows/
│       └── build.yml               # Automated Android & iOS build pipeline
├── lib/
│   ├── main.dart                   # App entrypoint and theme configuration
│   ├── models/
│   │   ├── task_item.dart          # Local representation of task + reflection data
│   │   ├── task_list.dart          # Google Tasks list model (id, title, updated)
│   │   └── task_filter.dart        # Filter states (All, Today, Planned, Completed, Cancelled)
│   ├── services/
│   │   ├── google_tasks_service.dart # OAuth & Google Tasks REST API client
│   │   ├── notification_service.dart # Local scheduled notifications wrapper
│   │   └── storage_service.dart    # Local persistence & offline cache
│   └── ui/
│       ├── home_screen.dart        # Task list view with search, filter, and sync
│       ├── task_list_switcher.dart # Clean dropdown/sheet to switch Google Task lists
│       ├── plan_task_dialog.dart   # Scheduling & time-planning sheet
│       └── cancel_reason_dialog.dart # Reflection dialog for cancellation reasons
├── test/
│   ├── models/
│   │   └── task_item_test.dart     # Unit tests for serialization and reflection parsing
│   └── services/
│       └── storage_service_test.dart
├── pubspec.yaml                    # Lean dependencies manifest
└── README.md
```

### 5.2 Dependencies (`pubspec.yaml`)
* `flutter` (SDK)
* `googleapis: ^13.2.0` (Official Google API client for Tasks v1)
* `google_sign_in: ^6.2.1` (Google OAuth authentication)
* `flutter_local_notifications: ^17.2.2` (Cross-platform scheduled alarms/notifications)
* `shared_preferences: ^2.2.3` (Lightweight offline caching)
* `intl: ^0.19.0` (Date and time formatting)

### 5.3 Data Model & Reflection Loop
```dart
enum TaskFilter { all, today, planned, completed, cancelled }

class TaskItem {
  final String id;
  final String taskListId;
  final String title;
  final String? notes;
  final DateTime? due;
  final DateTime? plannedTime;
  final bool isCompleted;
  final bool isCancelled;
  final String? cancelReason;
  final DateTime updatedAt;

  // Google Tasks API Mapping:
  // - Cancelled tasks are marked as status='completed' in Google Tasks so they clear
  //   from active task views in Google's native UI.
  // - Cancellation details are serialized into notes:
  //   "\n---\n[Cancelled: {reason} on {date}]"
  // - Planned alarm times are scheduled locally and serialized to notes:
  //   "[Planned: {ISO-8601}]" to preserve schedule across devices.
}
```

### 5.4 GitHub Actions CI Workflow (`.github/workflows/build.yml`)
1. **Lint & Test:** Runs `flutter test` and `flutter analyze` on `ubuntu-latest`.
2. **Android Build:** Runs `flutter build apk --release` on `ubuntu-latest` and uploads APK artifact.
3. **iOS Build:** Runs `flutter build ios --no-codesign` on `macos-latest` to verify iOS compilation integrity.

---

## 6. Builder Calls & Implementation Details

* **Cancelled Task Mapping (Builder Call):** Mapped to Google Tasks `completed` status so items clear from Google's active queue, while parsing `[Cancelled: ...]` from the notes field to populate the app's dedicated `Cancelled` filter tab.
* **Cross-Device Planning (Builder Call):** Alarms are scheduled locally via `flutter_local_notifications`, while `plannedTime` is persisted in the Google Task's notes as `[Planned: ISO-8601]` so the scheduled time isn't lost if you reinstall or open on another device.
* **Exact UI Nuances (Builder Call):** Clean Material 3 adaptive design with light/dark theme support.
* **Mock Google Service (Builder Call):** Provide an offline mock/demo mode so the app and tests can run fully even without live Google OAuth client credentials.
