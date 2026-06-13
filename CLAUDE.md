# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

- **Run app**: `flutter run`
- **Run on specific platform**: `flutter run -d windows` (or `android`, `ios`, `web`, `macos`, `linux`)
- **Install dependencies**: `flutter pub get`
- **Run all tests**: `flutter test`
- **Run single test file**: `flutter test test/widget_test.dart`
- **Analyze code (lint)**: `flutter analyze`
- **Build release APK**: `flutter build apk`
- **Build Windows**: `flutter build windows`

## Project Setup

- **Flutter SDK**: `^3.11.4`
- **Dart SDK constraint**: `^3.11.4`
- **Package name**: `com.example.flutter_application_1`
- **Linting**: Uses `flutter_lints` (configured in `analysis_options.yaml`)
- **Android**: Kotlin with Java 17 target, Gradle Kotlin DSL (`build.gradle.kts`), minSdk 26 (required for WebGL 2.0 in 3D charts), MultiDex enabled

## Architecture

Battery Discharge Logger (BDL) application for managing battery discharge tests. The app tracks battery tests with configurable cell count (6-24, default 24) and test duration (1-6 hours, default 6) with hourly voltage readings, generates PDF reports, and supports audio/visual alarms with local notifications.

### Directory Structure

- `lib/main.dart` - Entry point with `BDLApp` (MaterialApp root), MultiProvider setup (ThemeProvider, TestProvider, AlarmProvider)
- `lib/models/` - Data models: `BatteryTest`, `HourlyReading`, `CellVoltage`, `Customer`, `ServiceProvider`
- `lib/providers/` - State management using Provider: `TestProvider` (test lifecycle via DatabaseService), `AlarmProvider` (hourly countdown timers, vibration, audio, local notifications), `ThemeProvider` (light/dark mode)
- `lib/services/` - `DatabaseService` (SQLite via sqflite, singleton), `ReportService` (PDF generation via `pdf` package, singleton), `FeedbackService`
- `lib/screens/` - `TestListScreen` (home), `DataEntryScreen` (voltage input), `ReportScreen` (PDF preview/share)
- `lib/widgets/` - Dialogs (`ProviderInfoDialog`, `CustomerInfoDialog`), `Graph3DWidget` (ECharts 3D surface chart via InAppWebView), `TestListItem`
- `lib/utils/` - `constants.dart` (AppColors, AppConstants, AppStrings), `app_theme.dart`, `formatters.dart`, `validators.dart`, `page_transitions.dart`, `webview_config.dart`

Each subdirectory uses barrel files (e.g., `models.dart`, `providers.dart`, `services.dart`, `screens.dart`, `widgets.dart`, `utils.dart`) for exports.

### Key Patterns

- **Singletons**: `DatabaseService` and `ReportService` use factory constructor + `_internal()` pattern
- **State management**: Provider with `ChangeNotifier` — providers call `notifyListeners()` after state changes
- **Database**: SQLite with schema versioning (`onUpgrade`), readings stored as JSON-encoded list in `battery_tests` table
- **3D Charts**: `Graph3DWidget` renders ECharts 3D surface charts via `flutter_inappwebview` WebView — not native Flutter rendering

### Key Domain Concepts

- **Test Flow**: Start Test → Provider Info → Customer Info → Battery Photo → Hourly Readings → Report
- **Voltage Thresholds**: Critical < 1.70V (red), Warning 1.70-1.95V (yellow), Normal > 1.95V (green) — defined in `AppConstants`
- **Test Status**: `ongoing`, `stopped`, `completed` (stored as integer index in DB)
- **Auto-stop**: Tests auto-flag when any cell has critical voltage (`shouldStopDueToLowVoltage()`)
- **Alarm System**: `AlarmProvider` manages per-test 1-hour countdown timers with vibration, audio, and scheduled local notifications

### Platform Differences

- **Windows/Linux/macOS**: Image picker uses gallery (no camera support)
- **Mobile (Android/iOS)**: Image picker uses camera for battery photos
- **Notifications**: Android requires explicit notification permission request; iOS uses Darwin notification settings
