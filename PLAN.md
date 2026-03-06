# Magic Doodle — Implementation Plan

> **Version:** 1.0 · **Author:** Senior Architect · **Status:** Approved
> **Methodology:** Iterative Sprints (2-week cycles) · **Total Duration:** ~10 weeks

---

## 0. Architectural Decisions Record (ADR)

| #   | Decision                          | Rationale                                                                 | Alternatives Considered                 |
| --- | --------------------------------- | ------------------------------------------------------------------------- | --------------------------------------- |
| 001 | **flutter_bloc** for state        | Predictable, testable, strong ecosystem. Fits BLoC-per-feature pattern.   | Riverpod (less mature for large teams)  |
| 002 | **Hive** for local persistence    | No native deps, fast, works on all platforms. Perfect for offline-first.  | SQLite (heavier), Isar (less stable)    |
| 003 | **Isolate** for TFLite inference  | Non-blocking UI at 60fps while AI processes at 3-5 FPS.                   | Compute() (less control), Platform Channel (complex) |
| 004 | **GetIt + Injectable** for DI     | Compile-time safe, minimal boilerplate, auto-registration.                | Riverpod (couples state+DI), Manual DI  |
| 005 | **go_router** for navigation      | Declarative, deep-link support, guard middleware.                         | auto_route (code-gen heavy)             |
| 006 | **dartz Either** for errors       | Functional error handling, no exceptions crossing layers.                 | Sealed Result class (more boilerplate)  |
| 007 | **Firebase Emulator** for dev     | Local testing without quota, deterministic tests.                         | Mock classes (less realistic)           |

---

## 1. Phase 0 — Foundation & Tooling (Sprint 0)

**Duration:** 3-4 days
**Goal:** Zero-to-running. Every developer can clone, run, and see a blank screen.

### Tasks

| #    | Task                                      | Owner    | Acceptance Criteria                                                | Priority |
| ---- | ----------------------------------------- | -------- | ------------------------------------------------------------------ | -------- |
| 0.1  | `flutter create` + clean default files    | Lead     | `flutter run` shows blank MaterialApp on emulator                  | P0       |
| 0.2  | Apply Clean Architecture folder structure | Lead     | All folders + placeholder `.dart` files exist per `lib/README.md`  | P0       |
| 0.3  | Configure `pubspec.yaml` dependencies     | Lead     | `flutter pub get` succeeds with all packages listed                | P0       |
| 0.4  | Setup GetIt + Injectable DI container     | Lead     | `injection_container.dart` compiles, `build_runner` generates code | P0       |
| 0.5  | Setup Firebase project (iOS + Android)    | DevOps   | `google-services.json` & `GoogleService-Info.plist` configured     | P0       |
| 0.6  | Setup Firebase Emulator Suite             | DevOps   | `firebase emulators:start` runs Firestore + Storage locally        | P0       |
| 0.7  | Configure CI pipeline (GitHub Actions)    | DevOps   | `flutter test` + `flutter analyze` run on every PR                 | P1       |
| 0.8  | Create `.env.example` + environment config| Lead     | Dev/Staging/Prod Firebase configs separated                        | P1       |
| 0.9  | Configure `.gitignore` for Flutter        | Lead     | `build/`, `.dart_tool/`, secrets excluded                          | P0       |

### Deliverable
- ✅ Any developer can `git clone` → `flutter pub get` → `flutter run` → see splash screen
- ✅ CI pipeline green

### Dependencies
- Firebase project must be created by DevOps before 0.5
- Apple Developer account needed for iOS builds

---

## 2. Phase 1 — Domain Layer (Sprint 1, Week 1-2)

**Duration:** 2 weeks
**Goal:** All business rules defined, fully tested, zero framework dependencies.

### Tasks

| #    | Task                                              | Owner    | Acceptance Criteria                                            | Priority |
| ---- | ------------------------------------------------- | -------- | -------------------------------------------------------------- | -------- |
| 1.1  | Define `DrawingEntity`                            | Dev A    | Immutable, uses `Equatable`, has `copyWith`                    | P0       |
| 1.2  | Define `RecognitionResultEntity`                  | Dev A    | Fields: label, confidence, timestamp, category                 | P0       |
| 1.3  | Define `Asset3DEntity`                            | Dev A    | Fields: localPath, remotePath, audioPath, vocabulary, language  | P0       |
| 1.4  | Define `UsageLogEntity`                           | Dev A    | Fields: sessionId, wordsLearned, duration, isOffline, timestamp | P0       |
| 1.5  | Define `RecognitionRepository` interface          | Dev B    | Abstract class with `classify()` method, returns `Either`      | P0       |
| 1.6  | Define `AssetRepository` interface                | Dev B    | Abstract: `getAsset()`, `cacheAllAssets()`, `hasLocalCache()`  | P0       |
| 1.7  | Define `SyncRepository` interface                 | Dev B    | Abstract: `uploadFailedDrawings()`, `connectivityStream()`     | P0       |
| 1.8  | Define `UsageLogRepository` interface             | Dev B    | Abstract: `logSession()`, `getLocalLogs()`                     | P1       |
| 1.9  | Implement `RecognizeDrawingUseCase`               | Dev A    | Calls repository.classify(), handles Either, single `call()`   | P0       |
| 1.10 | Implement `FetchAssetUseCase`                     | Dev A    | Local-first lookup, returns Either<Failure, Asset3D>           | P0       |
| 1.11 | Implement `CacheAssetsUseCase`                    | Dev B    | Checks connectivity → downloads → stores locally               | P0       |
| 1.12 | Implement `SyncFailedDrawingsUseCase`             | Dev B    | Reads Hive queue → uploads batch → clears synced items         | P1       |
| 1.13 | Implement `LogUsageUseCase`                       | Dev B    | Writes to local store, queues for Firestore sync               | P1       |
| 1.14 | Define `Failure` sealed classes                   | Dev A    | `ServerFailure`, `CacheFailure`, `InferenceFailure`, `NetworkFailure` | P0 |
| 1.15 | Write unit tests for ALL use cases                | Both     | ≥90% coverage on domain layer, all Either paths tested         | P0       |

### Deliverable
- ✅ `domain/` compiles with `dart analyze` — zero warnings
- ✅ `flutter test test/unit/domain/` — all green
- ✅ **Zero** imports of `package:flutter`, `package:cloud_firestore`, or `package:tflite_flutter`

### Quality Gate
```bash
# Must pass before merging
flutter test test/unit/domain/ --coverage
# Coverage report must show ≥90% for domain/
```

---

## 3. Phase 2 — Data Layer: Local + ML (Sprint 2, Week 3-4)

**Duration:** 2 weeks
**Goal:** Offline persistence works. TFLite model loads and classifies on-device.

### Tasks

| #    | Task                                              | Owner    | Acceptance Criteria                                               | Priority |
| ---- | ------------------------------------------------- | -------- | ----------------------------------------------------------------- | -------- |
| 2.1  | Setup Hive + generate TypeAdapters                | Dev A    | `HiveService.init()` opens boxes, adapters registered             | P0       |
| 2.2  | Implement `DrawingLocalDatasource`                | Dev A    | Save/retrieve/delete failed drawings from Hive box                | P0       |
| 2.3  | Implement `AssetLocalDatasource`                  | Dev A    | Cache `.glb` + audio to app documents dir, retrieve by label      | P0       |
| 2.4  | Implement `DrawingModel` (toJson/fromJson/toHive) | Dev A    | Round-trip serialization test passes                               | P0       |
| 2.5  | Implement all other Models                        | Dev A    | Each model extends entity + has serialization                      | P0       |
| 2.6  | Integrate TFLite model file into `assets/`        | Dev B    | `quickdraw_model.tflite` in `assets/ml_models/`                   | P0       |
| 2.7  | Implement `ModelLoader`                           | Dev B    | Loads `.tflite` from assets, handles versioning                    | P0       |
| 2.8  | Implement `TFLiteService`                         | Dev B    | `Interpreter` lifecycle: load → run → dispose                     | P0       |
| 2.9  | Implement `InferenceIsolate`                      | Dev B    | Runs classification on separate Isolate, returns via SendPort      | P0       |
| 2.10 | Implement `DrawingClassifier`                     | Dev B    | Pre-process (resize 28x28, grayscale, normalize) → feed → parse   | P0       |
| 2.11 | Implement `RecognitionRepositoryImpl`             | Dev B    | Delegates to classifier, wraps in Either, handles errors           | P0       |
| 2.12 | Implement `AssetRepositoryImpl`                   | Dev A    | Check local → fallback remote → cache for next time                | P0       |
| 2.13 | Wire local datasources into DI container          | Lead     | `GetIt.I<DrawingLocalDatasource>()` resolves correctly             | P0       |
| 2.14 | Write unit tests for ML pipeline                  | Dev B    | Mock Interpreter, verify pre-processing dimensions                 | P0       |
| 2.15 | Write unit tests for local datasources            | Dev A    | Hive CRUD operations tested with in-memory adapter                 | P0       |

### Deliverable
- ✅ `flutter test test/unit/data/` — all green
- ✅ TFLite model loads on a real Android device without crash
- ✅ Classification of a test image returns correct label in <200ms on Pixel 6

### Risk Mitigation
| Risk                                      | Mitigation                                                |
| ----------------------------------------- | --------------------------------------------------------- |
| TFLite model too large (>50MB)            | Apply INT8 quantization, target <10MB                     |
| Isolate communication overhead            | Use `TransferableTypedData` for zero-copy frame transfer  |
| Hive box corruption on force-kill         | Wrap writes in `try-catch`, implement recovery logic      |

---

## 4. Phase 3 — Data Layer: Firebase Remote (Sprint 3, Week 5-6)

**Duration:** 2 weeks
**Goal:** Cloud sync fully operational. Offline queue drains when online.

### Tasks

| #    | Task                                              | Owner    | Acceptance Criteria                                               | Priority |
| ---- | ------------------------------------------------- | -------- | ----------------------------------------------------------------- | -------- |
| 3.1  | Implement `FirestoreService`                      | Dev A    | Generic CRUD wrapper for Firestore with typed responses            | P0       |
| 3.2  | Implement `FirebaseStorageService`                | Dev A    | Download 3D models + audio, upload failed drawings                 | P0       |
| 3.3  | Design Firestore schema                           | Lead     | Collections: `usage_logs`, `failed_drawings`, `asset_manifest`     | P0       |
| 3.4  | Implement `SyncRepositoryImpl`                    | Dev B    | Connectivity stream → batch upload → update local state            | P0       |
| 3.5  | Implement `UsageLogRepositoryImpl`                | Dev B    | Write-local-first → queue → sync to Firestore                     | P1       |
| 3.6  | Implement `ConnectivityService`                   | Dev A    | Stream<ConnectivityStatus> using `connectivity_plus`               | P0       |
| 3.7  | Implement `NetworkInfo` utility                   | Dev A    | `isConnected` getter, debounced to avoid flapping                  | P0       |
| 3.8  | Setup Firestore Security Rules                    | DevOps   | Write rules that match schema, test with emulator                  | P1       |
| 3.9  | Setup Firebase Storage Rules                      | DevOps   | Read-only for 3D assets, write for failed drawings (authenticated) | P1       |
| 3.10 | Integration test: full sync cycle                 | Both     | Offline write → go online → verify Firestore has data              | P0       |
| 3.11 | Integration test with Firebase Emulator           | Both     | `firebase emulators:exec "flutter test test/integration/"`         | P0       |

### Deliverable
- ✅ App works fully offline after first asset download
- ✅ When Wi-Fi reconnects, failed drawings upload within 30 seconds
- ✅ Usage logs appear in Firestore console after sync

### Quality Gate
```bash
# Integration tests with Firebase Emulator
firebase emulators:exec "flutter test test/integration/ --timeout 120s"
```

---

## 5. Phase 4 — Presentation Layer (Sprint 4-5, Week 6-8)

**Duration:** 2-3 weeks
**Goal:** Full UI implementation. Child can use the app end-to-end.

### Tasks

| #    | Task                                              | Owner    | Acceptance Criteria                                               | Priority |
| ---- | ------------------------------------------------- | -------- | ----------------------------------------------------------------- | -------- |
| 4.1  | Implement `SplashScreen`                          | Dev A    | Logo animation → permission check → navigate                      | P0       |
| 4.2  | Implement `CameraBloc` (full state machine)       | Dev B    | States: Uninitialized→Initializing→Streaming→Capturing→Disposing   | P0       |
| 4.3  | Implement `CameraScreen` + `CameraViewfinder`     | Dev A    | Live preview fills screen, guide overlay shows                     | P0       |
| 4.4  | Implement `ScanGuideOverlay`                      | Dev A    | Visual hint showing where to place paper (animated border)         | P1       |
| 4.5  | Implement `RecognitionBloc` (full state machine)  | Dev B    | States: Idle→PreProcessing→Inferring→Recognized→Unrecognized       | P0       |
| 4.6  | Implement `ResultScreen` + `ARModelRenderer`      | Dev A    | 3D model renders, rotates via touch, auto-rotate option            | P0       |
| 4.7  | Implement `ARAudioPlayer`                         | Dev A    | Play bilingual audio: "Apple — Quả Táo", with visual indicator    | P0       |
| 4.8  | Implement `SyncBloc`                              | Dev B    | Background connectivity monitoring, auto-sync queue                | P1       |
| 4.9  | Implement `OnboardingBloc`                        | Dev B    | First launch: download progress, permission flow                   | P1       |
| 4.10 | Implement `BigButton` widget                      | Dev A    | Extra large hit target (min 72x72dp), no text, icon-only           | P0       |
| 4.11 | Implement `LoadingOverlay` widget                 | Dev A    | Full-screen semi-transparent with animated mascot                  | P1       |
| 4.12 | Implement `AnimatedFeedback` widget               | Dev A    | Celebrate on recognition: confetti/sparkle animation               | P1       |
| 4.13 | Implement `ConfidenceIndicator` widget            | Dev A    | Visual bar showing AI confidence (for parent/debug mode)           | P2       |
| 4.14 | Implement `HistoryScreen` + `DrawingCard`         | Dev B    | Grid of past drawings, pull-to-refresh from local cache            | P1       |
| 4.15 | Implement `SettingsScreen` + `ParentalGate`       | Dev B    | Screen-time controls, language toggle, require math puzzle to enter | P1      |
| 4.16 | Implement `AppRouter` (go_router)                 | Lead     | All routes defined, guards for permissions, transitions            | P0       |
| 4.17 | Implement `AppTheme`                              | Dev A    | Kid-friendly colors, large fonts, rounded corners, high contrast   | P0       |
| 4.18 | Widget tests for all screens                      | Both     | Golden tests for visual regression, interaction tests for BLoCs    | P0       |

### Deliverable
- ✅ End-to-end user flow works on real device:
  - Open app → Camera → Point at drawing → See 3D model → Hear audio
- ✅ App is usable by a 4-year-old (no text-based interactions)
- ✅ UI maintains 60fps during AI inference

### UX Validation Criteria (from spec.md)
| Criterion                              | Target                              |
| -------------------------------------- | ----------------------------------- |
| Button minimum touch target            | 72 x 72 dp                         |
| Text on interactive elements           | **None** (icon/image only)          |
| Time from capture to 3D display        | < 2 seconds                         |
| Camera preview frame drop during AI    | 0 frames dropped                    |
| Audio feedback latency                 | < 500ms after 3D appears            |

---

## 6. Phase 5 — Integration, Polish & Hardening (Sprint 6, Week 9-10)

**Duration:** 2 weeks
**Goal:** Production-ready. All edge cases handled. Performance benchmarked.

### Tasks

| #    | Task                                              | Owner    | Acceptance Criteria                                                | Priority |
| ---- | ------------------------------------------------- | -------- | ------------------------------------------------------------------ | -------- |
| 5.1  | End-to-end integration testing                    | QA       | 20+ scenarios covering all state machine transitions               | P0       |
| 5.2  | Performance profiling on low-end device           | Dev B    | Test on Redmi Note 9 or equivalent — must maintain 30fps minimum   | P0       |
| 5.3  | Memory leak audit (Flutter DevTools)              | Dev B    | No memory growth after 100 recognition cycles                      | P0       |
| 5.4  | Offline stress test                               | QA       | Airplane mode for 1 hour → reconnect → all data syncs correctly    | P0       |
| 5.5  | Battery consumption audit                         | Dev B    | <5% battery per 15 min session (camera + AI active)                | P1       |
| 5.6  | App size optimization                             | Lead     | APK < 50MB (with ML model), iOS bundle < 60MB                     | P1       |
| 5.7  | Accessibility audit                               | Dev A    | Semantics labels on all widgets, screen reader navigable            | P1       |
| 5.8  | Crash-free startup on cold boot                   | Both     | 100/100 startup success on 5 device types                          | P0       |
| 5.9  | Firebase Security Rules audit                     | DevOps   | Penetration test: no unauthenticated writes possible               | P0       |
| 5.10 | Error tracking integration (Crashlytics)          | DevOps   | All unhandled exceptions reported with stack traces                 | P0       |
| 5.11 | Analytics integration (Firebase Analytics)        | Dev A    | Key events tracked: `app_open`, `drawing_recognized`, `asset_viewed` | P1     |
| 5.12 | Create parent dashboard (Firestore reads)         | Dev B    | Parent can see child's learning stats in Settings                  | P2       |
| 5.13 | Screen-time enforcement                           | Dev B    | Auto-pause after configurable limit (default: 20 min)              | P1       |
| 5.14 | Write deployment documentation                    | Lead     | README: build commands, env setup, Firebase deploy, store submission | P1      |

### Deliverable
- ✅ Zero P0 bugs open
- ✅ All quality gates pass
- ✅ App submitted to Google Play Internal Testing + TestFlight

---

## 7. Quality Gates (Must Pass Before Release)

| Gate                      | Tool                         | Threshold                                  |
| ------------------------- | ---------------------------- | ------------------------------------------ |
| Static Analysis           | `flutter analyze`            | Zero warnings, zero errors                 |
| Domain Layer Coverage     | `flutter test --coverage`    | ≥ 90%                                      |
| Data Layer Coverage       | `flutter test --coverage`    | ≥ 80%                                      |
| Widget Test Coverage      | `flutter test --coverage`    | ≥ 70%                                      |
| Integration Tests         | Firebase Emulator Suite      | All scenarios pass                         |
| Performance (high-end)    | Flutter DevTools              | 60fps sustained, <200ms inference          |
| Performance (low-end)     | Flutter DevTools              | 30fps sustained, <500ms inference          |
| APK Size                  | `flutter build apk --analyze-size` | < 50MB                               |
| Security                  | Firebase Rules Simulator     | All unauthorized operations rejected       |
| Crash Rate                | Crashlytics                  | < 0.1% crash-free session rate             |

---

## 8. Risk Register

| #  | Risk                                 | Impact | Probability | Mitigation                                                     | Owner   |
| -- | ------------------------------------ | ------ | ----------- | -------------------------------------------------------------- | ------- |
| R1 | TFLite model accuracy < 70%         | High   | Medium      | Augment training data from Quick Draw, add rotation/noise      | Dev B   |
| R2 | Camera permission rejected (iOS 17+)| Medium | High        | Graceful fallback UI, re-request with explanation               | Dev A   |
| R3 | 3D model rendering lag on old phones | High   | Medium      | LOD (Level of Detail) models, reduce polygon count              | Dev A   |
| R4 | Hive migration breaking changes     | Medium | Low         | Version boxes, write migration scripts, test on upgrade path    | Dev A   |
| R5 | Firebase costs spike (storage)      | Medium | Medium      | Compress uploads, set budget alerts, enforce upload quotas       | DevOps  |
| R6 | App rejected by App Store (COPPA)   | High   | Medium      | No personal data collection, parental gate, privacy policy      | Lead    |
| R7 | Child accidentally exits app        | Low    | High        | Guided mode with minimal navigation, no swipe-to-close          | Dev A   |

---

## 9. Sprint Calendar

```
Week  1  ████████████████  Phase 0: Foundation + Phase 1 Start
Week  2  ████████████████  Phase 1: Domain Layer Complete
Week  3  ████████████████  Phase 2: Local Data + ML Pipeline
Week  4  ████████████████  Phase 2: ML Integration + Testing
Week  5  ████████████████  Phase 3: Firebase Remote + Sync
Week  6  ████████████████  Phase 3 Complete + Phase 4 Start
Week  7  ████████████████  Phase 4: Core UI (Camera + Recognition)
Week  8  ████████████████  Phase 4: Full UI + Widget Tests
Week  9  ████████████████  Phase 5: Integration + Performance
Week 10  ████████████████  Phase 5: Polish + Store Submission
```

---

## 10. Definition of Done (per Task)

A task is "Done" when:

1. ✅ Code written and compiles without warnings
2. ✅ Unit/Widget tests written and passing
3. ✅ Code reviewed by at least 1 peer
4. ✅ No `// TODO` left without a linked issue
5. ✅ Public functions have dartdoc comments
6. ✅ Changes tested on both Android emulator AND iOS simulator
7. ✅ PR passes CI pipeline (analyze + test)
8. ✅ Merged to `develop` branch via squash merge
