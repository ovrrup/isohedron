# Comprehensive Data Handling & Logic Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the core logic and data handling of Isohedron to achieve production-grade offline-first stability, race-condition-free Google Tasks bidirectional synchronization, atomic and crash-resilient file persistence with tombstone deletions, timezone-safe date normalization, and reactive `ChangeNotifier` state architecture.

**Architecture:**
- **Storage Layer**: Atomic file I/O with `.tmp` flushing, `.bak` automated fallback backups, and persistent deletion tombstones (`deletedTaskIds`).
- **Sync Reconciliation**: True bidirectional merge with ID replacement (`replaceTaskId`), remote deletion propagation, and duplicate prevention.
- **State Management**: Decouple `IsohedronAppController` into `lib/controllers/isohedron_app_controller.dart` extending `ChangeNotifier` with single-source-of-truth reactivity.
- **Date & Calendar Normalization**: Timezone-safe calendar-day matching for Google Tasks RFC 3339 UTC midnight timestamps.
- **Reflection Loop**: Proactive overdue/missed task detection and rescheduling/cancellation workflows.

**Tech Stack:** Dart 3 / Flutter 3.27, `googleapis` (Tasks v1), `google_sign_in`, `flutter_local_notifications`.

---

## Global Constraints
- Native compilation and release signing runs in GitHub Actions CI (`ubuntu-latest`).
- Keystore credentials and private keys must never be committed to git.
- User constraint: "after finishing every work update the pull request then accept it."
- Google Tasks sync must genuinely work with both Direct OAuth Access Token and Google Play Services.

---

## Review Focus & Failure Modes
1. **Zombie Task Resurrection**: A task deleted locally must not be resurrected from Google Tasks during sync.
2. **Duplicate Local Task ID on Sync**: Pushing an offline task (`local_task_...`) must replace its local entry with the remote ID (`MDEx...`), never creating duplicates.
3. **Corrupted JSON on Abrupt Exit**: Storage writes must be atomic; any aborted write must leave existing data intact and recoverable via `.bak`.
4. **UTC Midnight Date Drift**: Google Tasks due date (`2026-10-27T00:00:00.000Z`) must show as due today in negative UTC offsets (e.g., UTC-5 New York), not yesterday at 7 PM.
5. **Overdue Planned Tasks**: Planned tasks whose reminder time has passed without being marked done must be surfaced for reflection and rescheduling.

---

## Implementation Tasks

### Task 1: Atomic Storage Persistence & Tombstone Deletion Tracking
**Files:**
- Modify: `lib/services/storage_service.dart`
- Test: `test/services/storage_service_test.dart`

- [ ] Add atomic file persistence: write to `${_storageFile.path}.tmp`, flush, and rename to `${_storageFile.path}`.
- [ ] Maintain `${_storageFile.path}.bak` backup before replacing main database file; add corrupt JSON fallback recovery.
- [ ] Add `Set<String> _deletedTaskIds` persisted in JSON schema (`deletedTaskIds`).
- [ ] Add `getDeletedTaskIds()`, `markTaskDeleted(String taskListId, String taskId)`, and `purgeDeletedTaskId(String taskId)`.
- [ ] Add `replaceTaskId(String oldId, TaskItem newTask)` to seamlessly replace temporary local IDs with remote Google Task IDs.
- [ ] Add `createTaskList(String title)` and `deleteTaskList(String listId)` with cascade cleanup of tasks and tombstones.
- [ ] Write unit tests verifying atomic write, `.bak` recovery, tombstones, and ID replacement.

### Task 2: Robust Bidirectional Sync & Deletion Propagation
**Files:**
- Modify: `lib/services/google_tasks_service.dart`
- Test: `test/services/google_tasks_service_test.dart`

- [ ] Add `deleteTask(String taskListId, String taskId)` and `deleteTaskList(String taskListId)` to `GoogleTasksClient`, `MockGoogleTasksClient`, and `LiveGoogleTasksClient`.
- [ ] Refactor `syncList(String taskListId, StorageService storage)`:
  1. Propagate deletions: For every ID in `storage.getDeletedTaskIds()`, delete from remote and call `storage.purgeDeletedTaskId(id)`.
  2. Filter remote tasks: Skip any remote task that matches a tombstone.
  3. Promote offline tasks: When pushing tasks with `local_` IDs, call `storage.replaceTaskId(local.id, pushedTask)`.
  4. Conflict resolution: Compare `updatedAt` timestamps; newer modification wins.
- [ ] Write unit tests verifying remote deletion propagation, tombstone filtering, and ID promotion.

### Task 3: Timezone-Safe Date Normalization
**Files:**
- Modify: `lib/models/task_item.dart`
- Modify: `lib/services/storage_service.dart`
- Test: `test/models/task_item_test.dart`

- [ ] Google Tasks `due` date-only parser: parse calendar year, month, and day without UTC midnight timezone distortion.
- [ ] Implement `isSameCalendarDay(DateTime date1, DateTime date2)` that respects date-only semantics.
- [ ] Update `StorageService.filterTasks` for `TaskFilter.today` to use calendar-day comparison.
- [ ] Add test cases testing UTC-5, UTC+0, and UTC+9 date filtering.

### Task 4: Reactive Controller (`ChangeNotifier` & Decoupled State)
**Files:**
- Create: `lib/controllers/isohedron_app_controller.dart`
- Modify: `lib/ui/home_screen.dart`
- Modify: `lib/main.dart`

- [ ] Move `IsohedronAppController` out of `home_screen.dart` into `lib/controllers/isohedron_app_controller.dart`.
- [ ] Extend `ChangeNotifier` and add `notifyListeners()` on all state mutations (task create, complete, cancel, delete, switch list, sync, search, filter).
- [ ] Add `overdueTasks` getter returning active tasks with `plannedTime < DateTime.now()`.
- [ ] Refactor `HomeScreen` to use `ListenableBuilder(listenable: controller, ...)` eliminating manual `setState(() {})`.

### Task 5: Reflection Loop & Missed Task Workflow
**Files:**
- Create: `lib/ui/reflection_dialog.dart`
- Modify: `lib/ui/home_screen.dart`

- [ ] Add missed tasks banner/indicator when `controller.overdueTasks.isNotEmpty`.
- [ ] Provide 1-tap reflection dialog allowing user to:
  1. Reschedule planned time.
  2. Cancel with reflection reason (automatically formatted into notes).
  3. Mark as completed.
- [ ] When reopening a completed or cancelled task, cleanly reset cancellation state and reschedule alarm if needed.

### Task 6: Verification, Pull Request & Signed Rolling Release
- [ ] Run `bash test/scripts/workflow_syntax_test.sh` and Dart tests.
- [ ] Commit all changes to `feat/data-logic-redesign`.
- [ ] Open Pull Request and verify CI checks pass.
- [ ] Merge Pull Request into `main`.
- [ ] Trigger signed nightly release workflow and confirm published release asset.
