# iOS Minimal App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Isohedron into an authentic, minimalist iOS task manager adhering to Apple Human Interface Guidelines: clean SF-style typography, Apple system color hierarchy (pure system grouped backgrounds, hairline dividers, iOS system accents), grouped inset task cards, circular checklist toggles with haptic feedback, native Cupertino sliding segmented filter control, Cupertino action sheets and pickers, and a streamlined bottom action bar replacing Android FABs.

**Architecture:** Refactor `AppTheme` to expose Apple iOS system tokens (light/dark system grouped backgrounds, SF-style typography, Cupertino color schemes). Introduce modular iOS UI components (`IosTaskCell`, `IosSegmentedFilter`, `IosReflectionBanner`) for inset grouped lists and circular checklist toggles. Overhaul `HomeScreen`, dialogs (`PlanTaskDialog`, `CancelReasonDialog`, `ReflectionDialog`), and `OnboardingScreen` to deliver native Cupertino navigation, search, modal bottom sheets, and pickers.

**Tech Stack:** Flutter / Dart, `package:flutter/cupertino.dart`, `package:flutter/material.dart`, `package:flutter/services.dart` (HapticFeedback).

**Spec:** Redesign the app to feel like an authentic, minimal iOS application across looks, feel, interactions, and structure.

## Global Constraints
- Must adhere to iOS Human Interface Guidelines (HIG): clean typography, system grouped backgrounds, 10-12pt corner radii, hairline dividers.
- Circular checklist toggles must provide haptic feedback (`HapticFeedback.lightImpact()`).
- All existing core controller APIs and storage contracts must remain backward-compatible and intact.
- Flutter analyze must pass with 0 errors and 0 warnings.
- No bulky Android FABs or Material 3 navigation bars; bottom bar and navigation follow iOS patterns.

## Review Focus
1. Circular checkbox toggle state: toggling completion provides immediate visual feedback, strikethrough styling, and haptic response without list jitter.
2. Grouped inset cell layout: items in an inset list group have properly rounded corners and hairline dividers with 44px text indentation.
3. Dark mode contrast: pure OLED dark mode (`#000000` / `#1C1C1E`) ensures high contrast text, visible dividers, and appropriate elevated surface backgrounds (`#2C2C2E`).
4. Cupertino date picker interaction: scheduling a reminder via `CupertinoDatePicker` validates against past times and formats date/time cleanly.
5. Search & filter responsiveness: `CupertinoSlidingSegmentedControl` filter switching and search text filtering work seamlessly together with clean empty states.

---

### Task 1: iOS Theme & Design Tokens

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Create/Modify: `test/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: Flutter `ThemeData`, `ColorScheme`, `CupertinoThemeData`.
- Produces: `AppTheme.iosLightTheme`, `AppTheme.iosDarkTheme`, `AppTheme.systemBlue`, `AppTheme.systemGray`, `AppTheme.hairlineDivider`, `AppTheme.groupedBackground`, `AppTheme.secondaryGroupedBackground`.

- [ ] **Step 1: Write unit tests for iOS theme tokens and contrast**
Verify color tokens: system grouped background `#F2F2F7` (light) and `#000000` / `#1C1C1E` (dark), system blue `#007AFF` / `#0A84FF`, separator `#C6C6C8` / `#38383A`.

- [ ] **Step 2: Run test to verify failure/missing constants**
Confirm tests fail before updating `app_theme.dart`.

- [ ] **Step 3: Implement iOS theme tokens and CupertinoThemeData in `lib/theme/app_theme.dart`**
Define Apple system colors, typography styling (SF Pro letter spacing and weights), clean card/dialog themes with 12pt corner radius and zero elevation.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**
```bash
git add lib/theme/app_theme.dart test/theme/app_theme_test.dart
git commit -m "feat(theme): define authentic iOS design tokens, system colors, and Cupertino theme"
```

---

### Task 2: iOS Task Cell & Circular Checklist Toggle

**Files:**
- Create: `lib/ui/widgets/ios_task_cell.dart`
- Modify: `lib/ui/home_screen.dart` (import and cell usage)
- Create: `test/ui/widgets/ios_task_cell_test.dart`

**Interfaces:**
- Consumes: `TaskItem`, `TaskFilter`, callback functions (`onToggleComplete`, `onReschedule`, `onCancel`, `onDelete`).
- Produces: `IosTaskCell` widget with circular Reminders-style checklist toggle, haptic feedback, planned pill badge, and swipe dismissible actions.

- [ ] **Step 1: Write test for `IosTaskCell` widget**
Test checklist toggle callback invocation, title strike-through style when completed, overdue badge appearance, and custom note rendering.

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement `IosTaskCell` in `lib/ui/widgets/ios_task_cell.dart`**
Implement circular checkmark icon with smooth transition, headline text, secondary metadata row, 44px indented hairline divider, and `Dismissible` swipe actions.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**
```bash
git add lib/ui/widgets/ios_task_cell.dart test/ui/widgets/ios_task_cell_test.dart
git commit -m "feat(ui): implement iOS Reminders-style inset task cell with circular checklist toggle"
```

---

### Task 3: iOS Filter Segmented Control & Reflection Banner

**Files:**
- Create: `lib/ui/widgets/ios_segmented_filter.dart`
- Create: `lib/ui/widgets/ios_reflection_banner.dart`
- Create: `test/ui/widgets/ios_components_test.dart`

**Interfaces:**
- Consumes: `TaskFilter`, list of overdue `TaskItem`s, callbacks.
- Produces: `IosSegmentedFilter` (using `CupertinoSlidingSegmentedControl`), `IosReflectionBanner` (Apple callout style).

- [ ] **Step 1: Write tests for `IosSegmentedFilter` and `IosReflectionBanner`**
Test filter selection triggers onFilterChanged with haptic feedback; test reflection banner displays overdue count and triggers reflection action.

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement `IosSegmentedFilter` and `IosReflectionBanner`**
Build `CupertinoSlidingSegmentedControl` wrapper with clean typography and badges; build iOS callout banner with soft red/orange tint and rounded inset card.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**
```bash
git add lib/ui/widgets/ios_segmented_filter.dart lib/ui/widgets/ios_reflection_banner.dart test/ui/widgets/ios_components_test.dart
git commit -m "feat(ui): add Cupertino sliding segmented filter control and iOS reflection callout banner"
```

---

### Task 4: Cupertino Dialogs & Modal Pickers

**Files:**
- Modify: `lib/ui/plan_task_dialog.dart`
- Modify: `lib/ui/cancel_reason_dialog.dart`
- Modify: `lib/ui/reflection_dialog.dart`
- Modify: `test/ui/dialogs_test.dart`

**Interfaces:**
- Consumes: `TaskItem`, `PlanTaskHelper`, `CancelReasonController`, `ReflectionResult`.
- Produces: `showPlanTaskDialog` with `CupertinoDatePicker` modal popup, `showCancelReasonDialog` with `CupertinoActionSheet`, `showReflectionDialog` with iOS action sheet.

- [ ] **Step 1: Write/update tests in `test/ui/dialogs_test.dart`**
Verify helpers and ensure controller behavior preserves custom text and presets.

- [ ] **Step 2: Run test to verify it fails/passes**

- [ ] **Step 3: Refactor dialogs to native Cupertino modal sheets & pickers**
Convert `showPlanTaskDialog` to a Cupertino bottom modal sheet with quick shortcut pills and iOS date/time wheel picker. Convert reflection and cancellation prompts to Cupertino action sheets.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**
```bash
git add lib/ui/plan_task_dialog.dart lib/ui/cancel_reason_dialog.dart lib/ui/reflection_dialog.dart test/ui/dialogs_test.dart
git commit -m "feat(ui): redesign planning, reflection, and cancellation dialogs with Cupertino sheets and pickers"
```

---

### Task 5: iOS Home Screen Overhaul & Bottom Action Bar

**Files:**
- Modify: `lib/ui/home_screen.dart`
- Modify: `lib/ui/task_list_switcher.dart`

**Interfaces:**
- Consumes: `IsohedronAppController`, `IosTaskCell`, `IosSegmentedFilter`, `IosReflectionBanner`.
- Produces: Fully redesigned `HomeScreen` with iOS Large Title header, search bar, inset grouped list container, and iOS-style bottom action bar.

- [ ] **Step 1: Write smoke test for redesigned `HomeScreen`**
Ensure task creation triggers from bottom bar, filter selection updates visible tasks, and list switcher displays active list.

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement iOS layout and bottom bar in `HomeScreen`**
Replace Android FAB with pinned bottom bar containing "+ New Reminder" button and list switcher. Group task items into inset rounded containers (`Container` with 12pt radius and secondary grouped background). Add iOS-style search field with clear button.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**
```bash
git add lib/ui/home_screen.dart lib/ui/task_list_switcher.dart test/ui/app_smoke_test.dart
git commit -m "feat(ui): overhaul HomeScreen with iOS Large Title, grouped inset lists, and Cupertino bottom bar"
```

---

### Task 6: iOS Onboarding Screen Polish

**Files:**
- Modify: `lib/ui/onboarding_screen.dart`
- Modify: `test/ui/onboarding_screen_test.dart`

**Interfaces:**
- Consumes: `IsohedronAppController`.
- Produces: Modern iOS "Welcome to Isohedron" sheet with clean feature rows, SF-style typography, and Cupertino primary action button.

- [ ] **Step 1: Write test for iOS onboarding screen**
Verify continue action triggers onboarding completion and navigation to home.

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement iOS Welcome screen styling in `lib/ui/onboarding_screen.dart`**
Format as standard iOS welcome sheet: large title "Welcome to Isohedron", 3 feature bullets with colorful rounded squircle icons (Task Management, Reflection Loop, Offline Privacy), and prominent Cupertino button.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**
```bash
git add lib/ui/onboarding_screen.dart test/ui/onboarding_screen_test.dart
git commit -m "feat(ui): update onboarding screen to authentic Apple welcome sheet layout"
```

---

### Task 7: End-to-End Verification & Baseline Check

**Files:**
- All modified files

- [ ] **Step 1: Run project analysis and test suite**
Run all tests and verify all pass with zero syntax or analysis errors.

- [ ] **Step 2: Review git status and diff across the worktree branch**
Verify clean commits, no extraneous files, and pristine diff against `origin/main`.

- [ ] **Step 3: Commit any final polishing touches**
```bash
git commit --allow-empty -m "chore(release): complete iOS minimal app redesign on feat/ios-minimal-redesign"
```
