# Tap To Pests

Tap To Pests is a Flutter arcade game where the player taps moving pests during a 30-second session, earns one point per hit, and can retry or return home from the game-over screen.

## Project Documentation

For a high-level onboarding guide that maps the main controllers, screens, widgets, services, use cases, and important functions, see [`projectOverview.md`](projectOverview.md).

## Tech Stack

- Flutter
- Dart
- SQLite through `sqflite`
- Sound playback through `flutter_soloud`
- Haptics/vibration through `vibration` and Flutter platform feedback
- UI animation through Flutter animation APIs and `flutter_animate`

## Getting Started

```bash
flutter pub get
flutter run
```

## Main Flow

```text
main.dart
  -> MainBindings.init()
  -> SmashStressApp
  -> MainScreenController
  -> StartScreen
  -> GameScreen
```
