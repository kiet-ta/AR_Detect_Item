# Magic Doodle — `/lib` Architecture Guide

> **Version:** 1.0 · **Stack:** Flutter · Firebase · TensorFlow Lite
> **Architecture:** Clean Architecture · Offline-First · Edge AI

---

## 📐 Layer Dependency Rule

```
Presentation ──depends on──► Domain ◄──implements── Data
```

- **Domain** is the innermost layer. It has **ZERO** external dependencies.
- **Presentation** talks to **Domain** via Use Cases only.
- **Data** implements **Domain** repository contracts.
- **No layer may import upward.** (Data must never import Presentation.)

---

## 📁 Folder Map

```
lib/
├── core/              # Shared infrastructure (no business logic)
├── domain/            # Business rules (framework-agnostic)
├── data/              # External world adapters
├── presentation/      # UI + State Management
├── main.dart          # Entry point (dev)
└── app.dart           # MaterialApp root widget
```

---

## 🔧 `core/` — Shared Infrastructure

Cross-cutting concerns used by every layer. **Contains no business logic.**

| Sub-folder       | Responsibility                                                              | Key Files                                         |
| ---------------- | --------------------------------------------------------------------------- | ------------------------------------------------- |
| `constants/`     | App-wide constants, Firestore collection names, asset paths                 | `app_constants.dart`, `firestore_collections.dart` |
| `theme/`         | Visual design tokens — colors, typography, widget themes                    | `app_theme.dart`, `app_colors.dart`                |
| `network/`       | Online/Offline detection, connectivity stream                               | `network_info.dart`, `connectivity_service.dart`   |
| `utils/`         | Pure helper functions — logging, image pre-processing, audio playback       | `logger.dart`, `image_preprocessor.dart`           |
| `errors/`        | Failure & Exception classes (typed, exhaustive)                              | `failures.dart`, `exceptions.dart`                 |
| `di/`            | Dependency Injection setup (GetIt + Injectable)                             | `injection_container.dart`, `register_module.dart`  |

**Rule:** If a utility is feature-specific, it belongs in that feature's layer, not here.

---

## ⚙️ `domain/` — Business Rules (The Heart)

Pure Dart. No Flutter imports. No Firebase imports. No TFLite imports.
This layer defines **WHAT** the app does, never **HOW**.

### `domain/entities/`

Immutable business objects. They carry meaning, not serialization logic.

| Entity                        | Represents                                                                    |
| ----------------------------- | ----------------------------------------------------------------------------- |
| `drawing_entity.dart`         | A child's drawing capture — raw image bytes, timestamp, device info           |
| `recognition_result_entity.dart` | AI classification output — label, confidence score, category               |
| `asset_3d_entity.dart`        | A 3D model reference — file path, audio path, vocabulary word, language       |
| `usage_log_entity.dart`       | Session telemetry — words learned, session duration, offline flag              |

### `domain/repositories/`

**Abstract interfaces** (contracts). Data layer implements these.

| Repository                    | Contract                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------ |
| `recognition_repository.dart` | `Future<RecognitionResult> classify(DrawingImage image)`                        |
| `asset_repository.dart`       | `Future<Asset3D> getAsset(String label)`, `Future<void> cacheFromRemote()`     |
| `sync_repository.dart`        | `Future<void> uploadFailedDrawings()`, `Stream<ConnectivityStatus>`            |
| `usage_log_repository.dart`   | `Future<void> logSession(UsageLog log)`                                        |

### `domain/usecases/`

Single-responsibility actions. Each use case = one user story.

| Use Case                            | Story                                                                |
| ----------------------------------- | -------------------------------------------------------------------- |
| `recognize_drawing_usecase.dart`    | Take a camera frame → run TFLite → return label + confidence         |
| `fetch_3d_asset_usecase.dart`       | Given a label ("apple") → return the cached 3D model + audio         |
| `cache_assets_usecase.dart`         | On first launch / Wi-Fi available → download & cache all 3D assets   |
| `sync_failed_drawings_usecase.dart` | When online → upload low-confidence drawings for retraining          |
| `log_usage_usecase.dart`            | Record session stats to Firestore (parent dashboard data)            |

---

## 💾 `data/` — External World Adapters

Implements domain contracts. Handles serialization, caching, network calls, and ML inference.

### `data/datasources/local/`

Persistence to device storage via **Hive** (lightweight, no native deps).

| File                             | Responsibility                                                           |
| -------------------------------- | ------------------------------------------------------------------------ |
| `hive_service.dart`              | Hive initialization, box management, migration logic                     |
| `drawing_local_datasource.dart`  | Save/retrieve failed drawing images for later sync                       |
| `asset_local_datasource.dart`    | Cache 3D `.glb` files + audio files to app document directory            |

### `data/datasources/remote/`

Firebase integration — Firestore for structured data, Storage for binary assets.

| File                              | Responsibility                                                          |
| --------------------------------- | ----------------------------------------------------------------------- |
| `firestore_service.dart`          | CRUD operations on Firestore (usage logs, drawing metadata)             |
| `firebase_storage_service.dart`   | Download 3D models & audio from Firebase Storage bucket                 |

### `data/models/`

Data Transfer Objects. Extend domain entities with `toJson()` / `fromJson()`.

| Model                          | Maps To                       | Serialization                     |
| ------------------------------ | ----------------------------- | --------------------------------- |
| `drawing_model.dart`           | `DrawingEntity`               | Hive TypeAdapter + JSON           |
| `recognition_result_model.dart`| `RecognitionResultEntity`     | Plain JSON (from TFLite output)   |
| `asset_3d_model.dart`          | `Asset3DEntity`               | Firestore document ↔ Dart object  |
| `usage_log_model.dart`         | `UsageLogEntity`              | Firestore document ↔ Dart object  |

### `data/repositories/`

Concrete implementations of `domain/repositories/` interfaces.

| Implementation                      | Key Behavior                                                          |
| ----------------------------------- | --------------------------------------------------------------------- |
| `recognition_repository_impl.dart`  | Delegates to `TFLiteService`, runs on Isolate                         |
| `asset_repository_impl.dart`        | Checks local cache → falls back to Firebase Storage download          |
| `sync_repository_impl.dart`         | Listens to connectivity → batch uploads failed drawings when online   |
| `usage_log_repository_impl.dart`    | Writes to local Hive first → syncs to Firestore on connectivity      |

### `data/ml/`

Edge AI — TensorFlow Lite inference running **entirely on-device**.

| File                        | Responsibility                                                              |
| --------------------------- | --------------------------------------------------------------------------- |
| `tflite_service.dart`       | Load `.tflite` model, manage interpreter lifecycle                          |
| `model_loader.dart`         | Resolve model path from assets, handle versioning                           |
| `inference_isolate.dart`    | Run inference on a **separate Isolate** to keep UI at 60fps                 |
| `drawing_classifier.dart`   | Pre-process camera frame → feed to model → parse output labels + scores     |

**Critical Design:** TFLite inference MUST run on `Isolate` (background thread).
The camera stream sends ~3-5 FPS to the classifier without blocking the UI thread.

---

## 🎨 `presentation/` — UI Layer

Everything the user sees and touches. Delegates all logic to BLoC → UseCase.

### `presentation/bloc/`

State Management via **flutter_bloc**. One BLoC per distinct user concern.

| BLoC           | Manages                                                                         |
| -------------- | ------------------------------------------------------------------------------- |
| `camera/`      | Camera lifecycle: init → streaming → paused → disposed                          |
| `recognition/` | AI pipeline: idle → processing → recognized → failed → retry                   |
| `sync/`        | Background sync: checking → syncing → synced → offline                          |
| `onboarding/`  | First-launch flow: asset download progress, permission requests                 |

Each BLoC folder contains exactly 3 files:
- `*_bloc.dart` — Logic + event→state mapping
- `*_event.dart` — Exhaustive event sealed class
- `*_state.dart` — Exhaustive state sealed class

### `presentation/screens/`

Full-screen pages. Minimal logic — just compose widgets and connect BLoC.

| Screen          | User Sees                                                                     |
| --------------- | ----------------------------------------------------------------------------- |
| `splash/`       | App logo → check auth/permissions → navigate                                  |
| `camera/`       | Live camera preview + scan guide overlay (main screen)                        |
| `result/`       | 3D model viewer + rotating animation + bilingual audio playback               |
| `history/`      | Grid of previously recognized drawings (offline data)                         |
| `settings/`     | Parental controls — screen-time, language toggle, data usage                  |

### `presentation/widgets/`

Reusable UI components, organized by domain.

| Sub-folder  | Contains                                                                        |
| ----------- | ------------------------------------------------------------------------------- |
| `common/`   | `BigButton` (oversized for kids 3-7), `LoadingOverlay`, `AnimatedFeedback`      |
| `camera/`   | `CameraViewfinder`, `ScanGuideOverlay` (shows where to place paper)             |
| `ar/`       | `ARModelRenderer` (3D object display), `ARAudioPlayer` (bilingual audio)        |
| `drawing/`  | `DrawingCard` (history tile), `ConfidenceIndicator` (AI confidence badge)       |

**UX Constraint (from spec):** Target users are 3-7 years old.
→ No text on interactive elements. Buttons must be extra large. Feedback must be real-time.

### `presentation/routes/`

App navigation powered by **go_router** or **auto_route**.

| File              | Responsibility                            |
| ----------------- | ----------------------------------------- |
| `app_router.dart` | Route definitions, guards, transitions    |

---

## 🔀 Data Flow — Offline-First Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    OFFLINE-FIRST FLOW                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Camera captures frame                                   │
│     └─► CameraBloc emits FrameCaptured event                │
│                                                             │
│  2. RecognitionBloc receives frame                          │
│     └─► Calls RecognizeDrawingUseCase                       │
│         └─► UseCase calls RecognitionRepository             │
│             └─► Repository runs TFLiteService on Isolate    │
│                                                             │
│  3. If confidence ≥ 70%:                                    │
│     └─► Fetch3DAssetUseCase (local cache first)             │
│         └─► Display 3D model + play audio                   │
│                                                             │
│  4. If confidence < 50% (Data Flywheel):                    │
│     └─► Save grayscale image to Hive (local)                │
│         └─► SyncBloc queues for upload                      │
│                                                             │
│  5. Background: SyncBloc monitors connectivity              │
│     └─► Online? Upload queued images to Firebase Storage    │
│     └─► Log usage session to Firestore                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Key Dependencies (pubspec.yaml)

| Package              | Purpose                        | Layer          |
| -------------------- | ------------------------------ | -------------- |
| `flutter_bloc`       | State management               | Presentation   |
| `get_it`             | Dependency injection           | Core           |
| `injectable`         | DI code generation             | Core           |
| `hive_flutter`       | Local persistence              | Data           |
| `cloud_firestore`    | Remote database                | Data           |
| `firebase_storage`   | File storage                   | Data           |
| `tflite_flutter`     | On-device ML inference         | Data           |
| `camera`             | Camera access                  | Presentation   |
| `model_viewer_plus`  | 3D model rendering             | Presentation   |
| `connectivity_plus`  | Network status detection       | Core           |
| `dartz`              | Functional error handling      | Domain         |
| `equatable`          | Value equality for entities    | Domain         |
| `go_router`          | Declarative routing            | Presentation   |

---

## 🚦 Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate DI + Hive adapters
dart run build_runner build --delete-conflicting-outputs

# 3. Run on device (debug)
flutter run

# 4. Run tests
flutter test

# 5. Build release
flutter build apk --release
```

---

## 📏 Conventions

| Concern          | Convention                                        |
| ---------------- | ------------------------------------------------- |
| File naming      | `snake_case.dart`                                 |
| Class naming     | `PascalCase`                                      |
| BLoC naming      | `{Feature}Bloc`, `{Feature}Event`, `{Feature}State` |
| Repository       | Interface in `domain/`, impl suffixed `_impl` in `data/` |
| Use Case         | One public `call()` method per class              |
| Models           | Extend entity, add `fromJson` / `toJson` / `fromFirestore` |
| Imports          | Package imports first, then relative (sorted)     |
| Error handling   | `Either<Failure, T>` from `dartz` — no exceptions crossing layer boundaries |
