# Isohedron Tasks: Minimal Task Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone, minimal, cross-platform task manager for iOS and Android with scheduled notifications, cancellation reflection prompts, optional Google Tasks sync integration, and automated GitHub Actions CI/CD workflows.

**Architecture:** Local-first architecture where the app functions completely standalone out of the box with offline task persistence, scheduled local notifications, and reflection tracking. Google Tasks acts as an optional integration provider for cross-device sync and Google ecosystem interoperability. GitHub Actions automatically verifies and builds release APKs and iOS project targets in the cloud.

**Tech Stack:** Flutter (Dart 3.x), `flutter_local_notifications`, `shared_preferences`, `googleapis`, `google_sign_in`, `intl`, GitHub Actions CI.

**Spec:** `docs/superpowers/specs/2026-10-27-minimal-task-manager-design.md`

## Global Constraints

* Target platforms: iOS and Android.
* Lean dependencies: Official Flutter and Google packages only (`googleapis`, `google_sign_in`, `flutter_local_notifications`, `shared_preferences`, `intl`); no heavy UI styling kits.
* CI/CD: Automated verification, linting, and Android/iOS compilation via GitHub Actions (`.github/workflows/build.yml`).
* Standalone first: App must operate 100% locally with zero required external sign-in or cloud dependencies.

## Review Focus

1. **Malformatted or externally modified note content:** User or external client edits task notes, corrupting metadata tags (`[Planned: ...]`, `[Cancelled: ...]`). Expected: Parser gracefully extracts clean notes and handles malformed timestamps without crashing.
2. **Offline & Unauthenticated operation:** User uses app without internet or without Google account. Expected: Operates frictionlessly on a local task list with local alarms and zero modal blockers.
3. **Past planned time:** User sets a planned time in the past. Expected: Rejects past time or fires reminder immediately rather than creating dead notifications.
4. **Blank cancellation reason:** User cancels task without typing a reason. Expected: Defaults to "No reason provided" and cleanly moves task to cancelled state.
5. **Multi-list offline switching:** User switches between cached task lists while disconnected. Expected: Loads local cached tasks instantly without hanging on network timeouts.

---

### Task 1: Project Scaffolding & GitHub Actions CI Pipeline

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `.gitignore`
- Create: `.github/workflows/build.yml`

**Interfaces:**
- Produces: Project manifest with lean dependencies, lint configuration, and CI workflow for automated testing and Android/iOS artifact builds.

- [ ] **Step 1: Create `.gitignore` for Flutter & Dart**
  Ensure git ignores build artifacts, `.dart_tool`, ephemeral iOS/Android generated files, and `.flutter-plugins`.

- [ ] **Step 2: Create `pubspec.yaml` with essential dependencies**
  Specify `flutter` SDK, `googleapis: ^13.2.0`, `google_sign_in: ^6.2.1`, `flutter_local_notifications: ^17.2.2`, `shared_preferences: ^2.2.3`, `intl: ^0.19.0`, and dev dependency `test: ^1.24.0` / `flutter_test`.

- [ ] **Step 3: Create `analysis_options.yaml`**
  Configure standard Flutter lints with strict type checking enabled.

- [ ] **Step 4: Create `.github/workflows/build.yml`**
  Define multi-job GitHub Actions workflow:
  * Job 1: `lint-and-test` on `ubuntu-latest` (runs `flutter analyze` and `flutter test`).
  * Job 2: `build-android` on `ubuntu-latest` (builds `flutter build apk --release` and uploads APK artifact).
  * Job 3: `build-ios` on `macos-latest` (builds `flutter build ios --no-codesign`).

- [ ] **Step 5: Run local dependency resolution and verify workflow syntax**
  Verify yaml structure and run `dart pub get` (or equivalent).

- [ ] **Step 6: Commit**
  ```bash
  git add pubspec.yaml analysis_options.yaml .gitignore .github/workflows/build.yml
  git commit -m "chore: scaffold project manifest and GitHub Actions CI workflow"
  ```

---

### Task 2: Data Models & Reflection In-Note Parser

**Files:**
- Create: `lib/models/task_item.dart`
- Create: `lib/models/task_list.dart`
- Create: `lib/models/task_filter.dart`
- Test: `test/models/task_item_test.dart`

**Interfaces:**
- Consumes: `intl`
- Produces:
  * `TaskFilter`: enum `{ all, today, planned, completed, cancelled }`
  * `TaskList`: `TaskList({required String id, required String title, bool isDefault, bool isLocal})`
  * `TaskItem`: `TaskItem({required String id, required String taskListId, required String title, String? notes, DateTime? due, DateTime? plannedTime, bool isCompleted, bool isCancelled, String? cancelReason, required DateTime updatedAt})`
  * `TaskItem.parseFromGoogleTask({required String id, required String taskListId, required String title, String? rawNotes, DateTime? due, required bool isCompleted, required DateTime updatedAt})`
  * `TaskItem.toGoogleNotes({String? userNotes, DateTime? plannedTime, String? cancelReason}) -> String`

- [ ] **Step 1: Write failing tests for `TaskItem` serialization & note parsing**
  Test parsing regular notes, notes with `[Planned: 2026-10-27T10:00:00Z]`, notes with `[Cancelled: Too busy on 2026-10-27]`, and corrupted notes.

- [ ] **Step 2: Run test to verify it fails**
  Run: `dart test test/models/task_item_test.dart`
  Expected: FAIL (modules not found)

- [ ] **Step 3: Implement `TaskFilter`, `TaskList`, and `TaskItem`**
  Implement models with immutable copyWith, JSON serialization, and robust regex-based note metadata extraction/formatting that never strips arbitrary user notes.

- [ ] **Step 4: Run test to verify it passes**
  Run: `dart test test/models/task_item_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/models test/models
  git commit -m "feat(models): implement TaskItem, TaskList, and reflection note parser"
  ```

---

### Task 3: Storage Service & Local-First Engine

**Files:**
- Create: `lib/services/storage_service.dart`
- Test: `test/services/storage_service_test.dart`

**Interfaces:**
- Consumes: `TaskItem`, `TaskList`, `TaskFilter`
- Produces:
  * `StorageService`:
    * `Future<void> init()`
    * `Future<List<TaskList>> getTaskLists()`
    * `Future<void> saveTaskLists(List<TaskList> lists)`
    * `Future<String> getSelectedTaskListId()`
    * `Future<void> setSelectedTaskListId(String id)`
    * `Future<List<TaskItem>> getTasks(String taskListId)`
    * `Future<void> saveTasks(String taskListId, List<TaskItem> tasks)`
    * `Future<void> upsertTask(TaskItem task)`
    * `Future<void> deleteTask(String taskListId, String taskId)`
    * `List<TaskItem> filterTasks(List<TaskItem> tasks, TaskFilter filter, {String searchQuery})`

- [ ] **Step 1: Write failing tests for `StorageService`**
  Test CRUD operations, offline default list creation, task filtering (Today, Planned, Cancelled), and local persistence.

- [ ] **Step 2: Run test to verify it fails**
  Run: `dart test test/services/storage_service_test.dart`
  Expected: FAIL

- [ ] **Step 3: Implement `StorageService`**
  Implement local persistence using JSON storage adapter with standalone local default list ("My Tasks") initialized if none exists.

- [ ] **Step 4: Run test to verify it passes**
  Run: `dart test test/services/storage_service_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/services/storage_service.dart test/services/storage_service_test.dart
  git commit -m "feat(services): implement local-first StorageService with offline filtering"
  ```

---

### Task 4: Notification Service

**Files:**
- Create: `lib/services/notification_service.dart`
- Test: `test/services/notification_service_test.dart`

**Interfaces:**
- Consumes: `TaskItem`
- Produces:
  * `NotificationService`:
    * `Future<void> init()`
    * `Future<bool> requestPermissions()`
    * `Future<void> scheduleTaskReminder(TaskItem task)`
    * `Future<void> cancelReminder(String taskId)`
    * `Future<void> cancelAll()`

- [ ] **Step 1: Write failing tests for `NotificationService`**
  Test scheduling validation (prevent scheduling in past without immediate trigger, unique notification ID hashing from task ID string).

- [ ] **Step 2: Run test to verify it fails**
  Run: `dart test test/services/notification_service_test.dart`
  Expected: FAIL

- [ ] **Step 3: Implement `NotificationService`**
  Wrap `flutter_local_notifications` with clean error handling, channel setup for Android ("Task Reminders"), and iOS authorization requests.

- [ ] **Step 4: Run test to verify it passes**
  Run: `dart test test/services/notification_service_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/services/notification_service.dart test/services/notification_service_test.dart
  git commit -m "feat(services): implement NotificationService for scheduled task alarms"
  ```

---

### Task 5: Google Tasks Integration & Sync Bridge

**Files:**
- Create: `lib/services/google_tasks_service.dart`
- Test: `test/services/google_tasks_service_test.dart`

**Interfaces:**
- Consumes: `TaskItem`, `TaskList`, `StorageService`
- Produces:
  * `GoogleTasksService`:
    * `bool get isAuthenticated`
    * `String? get userEmail`
    * `Future<bool> signIn()`
    * `Future<void> signOut()`
    * `Future<List<TaskList>> fetchTaskLists()`
    * `Future<List<TaskItem>> fetchTasks(String taskListId)`
    * `Future<TaskItem> pushTask(TaskItem task)`
    * `Future<void> syncList(String taskListId, StorageService storage)`

- [ ] **Step 1: Write failing tests for `GoogleTasksService`**
  Test sync reconciliation logic: remote task updates, pushing local completed/cancelled statuses with reflection notes, and mock demo provider fallback.

- [ ] **Step 2: Run test to verify it fails**
  Run: `dart test test/services/google_tasks_service_test.dart`
  Expected: FAIL

- [ ] **Step 3: Implement `GoogleTasksService`**
  Implement Google Tasks API client with `google_sign_in` and `googleapis.TasksApi`. Include a clean offline/mock fallback provider so integration testing works without OAuth credentials.

- [ ] **Step 4: Run test to verify it passes**
  Run: `dart test test/services/google_tasks_service_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/services/google_tasks_service.dart test/services/google_tasks_service_test.dart
  git commit -m "feat(services): implement GoogleTasksService sync bridge and mock provider"
  ```

---

### Task 6: UI Components & Reflection Dialogs

**Files:**
- Create: `lib/ui/cancel_reason_dialog.dart`
- Create: `lib/ui/plan_task_dialog.dart`
- Create: `lib/ui/task_list_switcher.dart`
- Test: `test/ui/dialogs_test.dart`

**Interfaces:**
- Consumes: `TaskItem`, `TaskList`
- Produces:
  * `CancelReasonDialog.show(BuildContext context, TaskItem task) -> Future<String?>`
  * `PlanTaskDialog.show(BuildContext context, {DateTime? initialTime}) -> Future<DateTime?>`
  * `TaskListSwitcher`: Widget showing current list title and dropdown/bottom-sheet selector for switching lists.

- [ ] **Step 1: Write unit tests for dialog return validation**
  Verify default values (e.g. blank input returns fallback default reason), date-time picker calculations.

- [ ] **Step 2: Run test to verify it fails**
  Run: `dart test test/ui/dialogs_test.dart`
  Expected: FAIL

- [ ] **Step 3: Implement UI dialogs & list switcher widget**
  Build clean Material 3 dialogs:
  * `CancelReasonDialog`: title, quick reason chips ("Ran out of time", "Deprioritized", "Waiting on something", "No longer needed") + custom text field.
  * `PlanTaskDialog`: Date and Time picker with quick shortcut buttons (+1 Hour, Tonight, Tomorrow Morning).
  * `TaskListSwitcher`: Clean app bar dropdown with indicator for local vs synced Google lists.

- [ ] **Step 4: Run test to verify it passes**
  Run: `dart test test/ui/dialogs_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/ui/cancel_reason_dialog.dart lib/ui/plan_task_dialog.dart lib/ui/task_list_switcher.dart test/ui/dialogs_test.dart
  git commit -m "feat(ui): implement cancel reflection dialog, plan picker, and list switcher"
  ```

---

### Task 7: Main App Entrypoint & Verification

**Files:**
- Create: `lib/ui/home_screen.dart`
- Create: `lib/main.dart`
- Modify: `README.md`
- Test: `test/ui/app_smoke_test.dart`

**Interfaces:**
- Consumes: All services, models, and UI components
- Produces: Complete working application with theme, task list view, add task sheet, search bar, filter tabs, and Google sync button.

- [ ] **Step 1: Write smoke test for app initialization**
  Verify application launches, loads default task list, and renders filter tabs.

- [ ] **Step 2: Implement `HomeScreen` and `main.dart`**
  Build `HomeScreen` with:
  * App bar featuring `TaskListSwitcher`, Google Tasks connect/sync status indicator, and settings/info.
  * Search field and filter chips: All, Today, Planned, Completed, Cancelled.
  * Task card with status checkbox, title, notes preview, planned time badge with alarm icon, and action menu.
  * Tapping checkbox marks Done; tapping "Cancel / Didn't Do" launches `CancelReasonDialog`.
  * FAB to quickly add task with optional immediate planning.

- [ ] **Step 3: Run full test suite**
  Run: `dart test`
  Expected: ALL PASS

- [ ] **Step 4: Update README.md with architecture and CI usage**
  Document project overview, standalone local usage, Google Tasks integration steps, and GitHub Actions build instructions.

- [ ] **Step 5: Commit**
  ```bash
  git add lib/ui/home_screen.dart lib/main.dart README.md test/ui/app_smoke_test.dart
  git commit -m "feat(app): implement HomeScreen, main entrypoint, and documentation"
  ```
