# Isohedron UI Redesign, Onboarding Flow & Brand Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

This plan details the comprehensive visual redesign of the Isohedron Flutter app, implementing a multi-screen first-launch onboarding experience with Google Tasks vs. Local mode selection, the official brand palette (`#1A6FBF`, `#F5F0E8`, `#D91A2A`), standardized `Isohedron` branding, and professional Android adaptive launcher and notification icons.

---

## User Review Required

> [!IMPORTANT]
> The brand color scheme has been mapped as:
> - **Primary Brand**: `#1A6FBF` (Cerulean Blue)
> - **Canvas / Surface Background**: `#F5F0E8` (Warm Linen Cream)
> - **Accent / Alert / Focus**: `#D91A2A` (Crimson)
>
> Onboarding provides two prominent terminal actions:
> 1. **Connect with Google**: Launches OAuth flow using the registered Android Client ID to synchronize with Google Tasks.
> 2. **Continue Locally**: Enters standalone mode without external network or account requirements.

---

## Proposed Changes

### 1. Theme and Design System (`lib/theme/app_theme.dart`)
- Define constants: `AppTheme.primary = Color(0xFF1A6FBF)`, `AppTheme.canvas = Color(0xFFF5F0E8)`, `AppTheme.accent = Color(0xFFD91A2A)`.
- Configure Material 3 `ColorScheme` for light and dark modes with comfortable contrast.
- Style `AppBarTheme`, `CardTheme`, `ElevatedButtonTheme`, `OutlinedButtonTheme`, `ChipThemeData`, `InputDecorationTheme`, and `FloatingActionButtonTheme`.

### 2. Onboarding Persistence & Controller (`lib/services/storage_service.dart` & `lib/controllers/isohedron_app_controller.dart`)
- Add `bool _hasCompletedOnboarding` flag to `StorageService` with getter and `setHasCompletedOnboarding(bool)`.
- Serialize and deserialize `hasCompletedOnboarding` in atomic storage JSON.
- Add `bool get hasCompletedOnboarding` and `Future<void> completeOnboarding()` to `IsohedronAppController`.

### 3. Logo & Emblem Widget (`lib/ui/widgets/isohedron_logo.dart`)
- Build a custom `CustomPainter` rendering a multifaceted regular icosahedron projection with shaded polygonal faces matching the palette (`#1A6FBF`, `#F5F0E8`, and `#D91A2A`).

### 4. First-Launch Onboarding Experience (`lib/ui/onboarding_screen.dart`)
- 3-slide PageView with smooth transition curves and pill page indicator:
  - Slide 1: **Sanctuary of Focus** — Introduction to Isohedron's geometric simplicity.
  - Slide 2: **Graceful Reflection** — Compassionate loop when days deviate from plans.
  - Slide 3: **Your Workspace, Your Choice** — Two primary action cards:
    - "Connect Google Tasks" (initiates Google OAuth flow)
    - "Continue Locally" (pure offline standalone)
- Smooth navigation to `HomeScreen` upon completing either action.

### 5. Home Screen Visual Polish & Branding (`lib/ui/home_screen.dart` & dialogs)
- Replace generic indigo styling with `AppTheme`.
- Integrate `IsohedronLogo` in AppBar and Account dialog.
- Standardize all app labels and titles to `Isohedron`.
- Polish task cards, filter chips, overdue alert banners, and reflection dialogs to feel comfortable and sleek.

### 6. Android App Icon & Notification Drawables
- Update `android/app/src/main/res/drawable/ic_launcher_background.xml` with `#F5F0E8`.
- Update `android/app/src/main/res/drawable/ic_launcher_foreground.xml` with faceted vector Isohedron.
- Generate high-res launcher PNG icons for all mipmap buckets (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- Update notification drawables (`ic_notification.png` and `ic_stat_notify.png`).

### 7. Automated Testing & Verification
- Test `StorageService.hasCompletedOnboarding` serialization.
- Test `IsohedronAppController` onboarding transition.
- Test `AppSmokeTest` verifying initial route switches correctly between onboarding and home.

---

## Verification Plan

### Automated Tests
- `test/services/storage_service_test.dart`
- `test/controllers/isohedron_app_controller_test.dart`
- `test/ui/app_smoke_test.dart`
- `bash test/scripts/workflow_syntax_test.sh`

### CI Verification
- Push branch `feat/ui-redesign-and-onboarding`.
- Create GitHub Pull Request.
- Monitor GitHub Actions checks (Flutter Analyze, Flutter Test, Android APK Build).
- Merge PR into `main`.
- Monitor Nightly Release workflow run on `main`.
