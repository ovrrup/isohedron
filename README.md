# Isohedron Tasks

Autonomous, zero-friction Universal AI Context Bridge and Minimal Task Manager for iOS & Android.

Isohedron Tasks is a local-first task manager built with high precision scheduling, an accountability reflection loop, and optional Google Tasks integration.

---

## Key Features

1. **Standalone & Local-First:**
   * Works completely offline out of the box with zero external login requirements.
   * Full local task persistence and list switching.

2. **Planning & Scheduled Alarms:**
   * Plan tasks for specific dates and times.
   * Cross-platform local notifications deliver timely alerts without draining battery.

3. **Reflection Loop:**
   * If a task is cancelled or marked not done, the app immediately prompts for the reason (preset chips + custom text).
   * Reflection reasons are stored in history and attached to task notes to surface patterns over time.

4. **Optional Google Tasks Integration:**
   * Use Google Tasks as a sync bridge across multiple devices.
   * Seamless two-way sync: completions and cancellation reasons sync back to Google Tasks notes (`[Cancelled: <reason>]`) so external clients stay in sync.
   * Multi-list switcher: switch between Local and Google Task lists.

---

## Architecture & Project Structure

```
.
├── .github/
│   └── workflows/
│       └── build.yml               # Automated Android & iOS GitHub Actions CI
├── lib/
│   ├── main.dart                   # Application entrypoint
│   ├── models/
│   │   ├── task_filter.dart        # Filter states (All, Today, Planned, Completed, Cancelled)
│   │   ├── task_item.dart          # Task model with reflection metadata parser/serializer
│   │   └── task_list.dart          # Local & Google task list abstractions
│   ├── services/
│   │   ├── google_tasks_service.dart # Google Tasks REST API client & mock sync bridge
│   │   ├── notification_service.dart # Local scheduled alarms & ID generator
│   │   └── storage_service.dart    # Local JSON persistence & filtering engine
│   └── ui/
│       ├── cancel_reason_dialog.dart # Reflection prompt dialog
│       ├── home_screen.dart        # App coordinator & main responsive view
│       ├── plan_task_dialog.dart   # Date/time scheduling picker & shortcut chips
│       └── task_list_switcher.dart # List switcher widget
└── test/
    ├── models/task_item_test.dart
    ├── services/google_tasks_service_test.dart
    ├── services/notification_service_test.dart
    ├── services/storage_service_test.dart
    ├── ui/app_smoke_test.dart
    └── ui/dialogs_test.dart
```

---

## Development & Testing

### Running Tests Locally
```bash
dart pub get
dart test
dart analyze
```

### Automated CI / CD
GitHub Actions automatically runs on every push:
* **Lint & Tests:** Runs analysis and unit tests on `ubuntu-latest`.
* **Android Build:** Compiles the Android APK and uploads release artifacts.
* **iOS Build:** Verifies macOS / iOS compilation without codesigning.
