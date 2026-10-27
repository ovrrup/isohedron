# Isohedron

A sovereign, 100% private offline geometric task sanctuary with an accountability reflection loop for Android.

Isohedron is designed around the philosophy of mindful focus and geometric calm. It operates completely offline with atomic local persistence, calendar-day rhythm, and a compassionate reflection loop when plans change.

---

## Brand Identity & Aesthetic

- **Primary Brand**: `#1A6FBF` (Cerulean Blue)
- **Background Canvas & Surfaces**: `#F5F0E8` (Warm Linen / Parchment)
- **Accent & Alerts**: `#D91A2A` (Crimson)
- **Geometric Icon**: Custom faceted icosahedron emblem with shaded polygons and central crimson jewel.

---

## Key Features

1. **100% Sovereign & Offline:**
   * Operates completely offline with zero accounts, cloud tracking, or network requests.
   * Atomic local JSON persistence (`.tmp` -> `.bak` -> primary) guarantees durability across sudden app terminations.
   * Full local task lists and custom multi-list switching.

2. **Planning & Scheduled Alarms:**
   * Plan tasks for specific calendar days and times.
   * Local device alarms and notifications deliver timely reminders without draining battery or requiring cloud push services.

3. **Compassionate Reflection Loop:**
   * When a planned task is missed or cancelled, Isohedron treats it with mindfulness rather than guilt or red panic numbers.
   * Overdue banners gently prompt reflection to reschedule, complete, or record why plans shifted.
   * Reflection reasons are preserved in task logs to surface patterns over time.

4. **First-Launch Onboarding:**
   * Guided multi-slide introduction to the geometric sanctuary and reflection philosophy.
   * Instant offline start with zero configuration.
   * Replayable at any time from the app's About menu.

---

## Architecture & Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── build.yml                 # Automated Android CI & quality gates
│       └── nightly.yml               # Automated signed APK rolling release
├── lib/
│   ├── main.dart                     # App entrypoint and reactive theme routing
│   ├── controllers/
│   │   └── isohedron_app_controller.dart # Central reactive state controller
│   ├── models/
│   │   ├── task_filter.dart          # Filter definitions (All, Today, Planned, Completed, Cancelled)
│   │   ├── task_item.dart            # Local task model with atomic serialization
│   │   └── task_list.dart            # Sovereign task list abstraction
│   ├── services/
│   │   ├── notification_service.dart # Local scheduled alarms & ID generator
│   │   └── storage_service.dart      # Atomic file persistence & filtering engine
│   ├── theme/
│   │   └── app_theme.dart            # Brand palette (#1A6FBF, #F5F0E8, #D91A2A) & M3 themes
│   └── ui/
│       ├── cancel_reason_dialog.dart # Reflection prompt dialog
│       ├── home_screen.dart          # Main task list, overdue banner, and About dialog
│       ├── onboarding_screen.dart    # First-launch 3-slide introductory carousel
│       ├── plan_task_dialog.dart     # Date/time scheduling picker & quick chips
│       ├── reflection_dialog.dart    # Overdue task reflection decision dialog
│       ├── task_list_switcher.dart   # Dropdown list switcher
│       └── widgets/
│           └── isohedron_logo.dart   # Custom-painted faceted icosahedron emblem
├── scripts/
│   └── generate_icons.js             # High-precision vector & raster icon generator
└── test/
    ├── controllers/isohedron_app_controller_test.dart
    ├── models/task_item_test.dart
    ├── scripts/workflow_syntax_test.sh
    ├── services/notification_service_test.dart
    ├── services/storage_service_test.dart
    ├── ui/app_smoke_test.dart
    └── ui/dialogs_test.dart
```

---

## Development & Automated Releases

### Running Quality Gates
```bash
bash test/scripts/workflow_syntax_test.sh
```

### Nightly Releases
- Automated signed nightly APK builds are published on every push to `main` and daily at 02:00 UTC.
- Download the latest signed build: [Isohedron Nightly Release](https://github.com/ovrrup/isohedron/releases/tag/nightly)
