# Magic Doodle ✨

[![Magic Doodle CI](https://github.com/kiet-ta/AR_Detect_Item/actions/workflows/ci.yml/badge.svg)](https://github.com/kiet-ta/AR_Detect_Item/actions/workflows/ci.yml)

An EdTech app that transforms children's hand-drawn sketches on real paper into interactive 3D models with bilingual audio, powered by on-device Edge AI (TensorFlow Lite).

## Features

- **Real-time drawing recognition** — TFLite classifier runs on-device at 3–5 FPS via Dart isolates, keeping the UI at 60 FPS.
- **3D model display** — Recognized drawings are matched to cached `.glb` 3D assets and displayed with bilingual (English/Vietnamese) audio.
- **Offline-first** — Assets are pre-cached from Firebase Storage on first launch; the app works fully offline afterwards.
- **Data Flywheel** — Low-confidence predictions (< 50 %) are binarized (Otsu's method, COPPA-safe) and queued for cloud upload to improve the model over time.
- **Parent dashboard** — Session logs track words learned and screen time, synced to Firestore when online.

## Architecture

```
Presentation → Domain ← Data
```

| Layer | Responsibility | Key packages |
|---|---|---|
| **Domain** | Entities, repository contracts, use cases | `equatable`, `dartz` |
| **Data** | Firebase, Hive, TFLite, file cache | `cloud_firestore`, `hive_flutter`, `tflite_flutter` |
| **Presentation** | Screens, BLoC state management, widgets | `flutter_bloc`, `go_router` |

See [`lib/README.md`](lib/README.md) for a detailed architecture guide.

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) **3.27.0** (stable channel)
- Dart SDK **≥ 3.3.0 < 4.0.0**
- Android SDK (for Android builds) or Xcode (for iOS builds)
- A Firebase project with Firestore, Storage, and Analytics enabled

## Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/kiet-ta/AR_Detect_Item.git
cd AR_Detect_Item

# 2. Copy and fill in environment variables
cp .env.example .env

# 3. Install dependencies
flutter pub get

# 4. Run code generation (Injectable DI, Hive adapters)
dart run build_runner build --delete-conflicting-outputs

# 5. Run the app
flutter run
```

## Running Tests

```bash
# Unit tests with coverage
flutter test --coverage

# Check formatting
dart format --output=none --set-exit-if-changed lib/ test/

# Static analysis (strict mode)
flutter analyze --fatal-infos
```

## Building

```bash
# Android release APK
flutter build apk --release

# iOS release (requires Xcode)
flutter build ios --release
```

## Project Structure

```
├── lib/
│   ├── core/           # Constants, DI, errors, networking, theme, utils
│   ├── data/           # Datasources, ML pipeline, models, repositories
│   ├── domain/         # Entities, repository contracts, use cases
│   ├── presentation/   # BLoC, routes, screens, widgets
│   ├── main.dart       # App entry point
│   └── app.dart        # MaterialApp root widget
├── test/               # Unit and widget tests
├── .github/workflows/  # CI/CD pipeline
└── spec.md             # Product specification (Vietnamese)
```

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before submitting a pull request.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
