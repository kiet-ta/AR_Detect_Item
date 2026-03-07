# Magic Doodle — Project Guidelines

## Architecture

**Pattern:** Clean Architecture (3-layer) with BLoC state management

```
Presentation → Domain ← Data
```

**Layer Dependency Rules:**
- Domain layer has **zero** external dependencies (no Flutter, Firebase, TFLite imports)
- Data layer implements domain repository contracts
- Presentation layer consumes domain use cases via BLoC
- **Never** import upward in the dependency chain

**Key Design Decisions:**
- **Isolate-based ML inference** prevents UI frame drops (60fps UI, 3-5fps inference)
- **Offline-first** via Hive local storage + Firebase auto-sync
- **Data flywheel** captures low-confidence predictions for model retraining
- **Either<Failure, T>** functional error handling — no exceptions across layers

See [PLAN.md](../PLAN.md) for architectural decision records.

## State Flows & Module Interactions

**Understanding Module Communication:**
The app follows a strict event-driven flow between BLoCs. See [state_machine.md](state_machine.md) for complete diagrams.

**Critical State Transitions:**

1. **App Launch Flow**
   ```
   AppStart → Firebase init → Hive init → DI → Camera permission → Connectivity check
   → Asset download (if first launch) → Camera ready
   ```
   - Online + first launch: Downloads 3D models and audio from Firebase Storage
   - Online + returning: Uses cached assets
   - Offline + cached: Full functionality
   - Offline + no cache: Blocks with "connect to Wi-Fi" screen

2. **Recognition Flow** (Core Loop)
   ```
   CameraBloc captures frame (3-5 FPS) → RecognitionBloc
   → ImagePreprocessor normalizes to 28×28 grayscale
   → InferenceIsolate runs TFLite on background thread
   → Confidence evaluation:
      ≥70%: Display 3D result + audio
      50-69%: Silently ignore (uncertain)
      <50%: Save to data flywheel for retraining
   ```
   - **Key insight**: Camera runs at device FPS (30-60), inference throttled to 3-5 FPS
   - Blank frames skipped by `ImagePreprocessor.isBlankFrame()`

3. **Data Flywheel Flow** (Low Confidence)
   ```
   Recognition result <50% confidence
   → Save grayscale 28×28 image to Hive (compressed)
   → Tag with `needs_retraining: true`
   → SyncBloc monitors connectivity
   → When Wi-Fi available: Batch upload to Firebase Storage
   → Firestore metadata updated for ML team
   ```

4. **Sync Flow** (Background)
   ```
   SyncBloc continuously listens to connectivity_plus stream
   → Wi-Fi detected → Check Hive for queued items
   → Batch upload failed drawings (priority)
   → Upload usage logs
   → Update Firestore metadata
   → On network loss: Pause, re-queue, retry on reconnect
   ```
   - Singleton BLoC persists across navigation
   - Exponential backoff on Firebase quota errors

**Module Interaction Rules:**

- **CameraBloc** → **RecognitionBloc**: Sends raw `CameraImage` via `FrameReceived` event
- **RecognitionBloc** → **InferenceIsolate**: Uses SendPort/ReceivePort, never shared memory
- **RecognitionBloc** → **UsageLogRepository**: Logs session after recognition
- **SyncBloc** listens to: Connectivity changes (reactive) + Hive watch (local changes)
- **All BLoCs** → **Repositories** → **Data Sources**: Never skip repository layer

**Error Recovery Patterns:**

| Scenario | Detection | Recovery |
|----------|-----------|----------|
| Camera permission denied | OS callback | Show prompt → deep-link to Settings |
| TFLite model load fails | Exception | Retry 3x → "restart app" message |
| Isolate crashes | Error port | Restart isolate, skip frame |
| Network lost during sync | Connectivity stream | Pause upload, re-queue, retry on reconnect |
| Hive corruption | HiveError | Clear box, re-download on Wi-Fi |
| Asset missing from cache | FileNotFound | Fallback placeholder, queue download |

See [state_machine.md](state_machine.md) for complete state diagrams and transition tables.

## Build and Test

**Setup:**
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # Required after DI changes
```

**Development:**
```bash
flutter run                    # Dev server (portrait-only)
flutter analyze --fatal-infos  # Must pass before commits
dart format --set-exit-if-changed .
```

**Testing:**
```bash
flutter test --coverage --coverage-package=magic_doodle
# Domain layer must maintain ≥90% coverage (CI enforced)
```

**Build:**
```bash
flutter build apk --release --obfuscate
```

**Critical:** Hive must initialize before DI in `main.dart`:
```dart
await Firebase.initializeApp();
await HiveService.init();        // Must be before DI
await configureDependencies();   // GetIt injection
```

## Code Style

**File Naming:** snake_case for all files (`recognize_drawing_usecase.dart`)

**Class Naming:**
- Use Cases: `{Action}{Noun}UseCase` (e.g., `RecognizeDrawingUseCase`)
- Repositories: Interface `{Noun}Repository`, implementation `{Noun}RepositoryImpl`
- BLoCs: `{Feature}Bloc`, `{Feature}Event`, `{Feature}State`
- Models: `{Entity}Model` (extends domain entity with serialization)

**Immutability:** Prefer `@immutable`, `const` constructors, and `final` fields

**Error Handling:**
- All risky operations return `Either<Failure, T>` (via dartz)
- Use typed failures: `InferenceFailure`, `NetworkFailure`, `CacheFailure`
- Handle both branches with `.fold(onLeft, onRight)`

**Dependency Injection:**
- Use `@injectable` for automatic registration
- Use `@Injectable(as: Interface)` for polymorphic bindings
- Use `@singleton` for app-lifetime instances (BLoCs, services)
- Always run `build_runner` after DI changes

**Logging:** Use `AppLogger` from `lib/core/utils/logger.dart` — never `print()`

## Conventions

**State Management:**
- BLoC pattern with event-driven handlers (`_on{EventName}`)
- Use `MultiBlocProvider` at app root
- Feature-specific BLoCs; `SyncBloc` is singleton
- All states extend from sealed-like base class and use `Equatable`

**ML/TFLite Integration:**
- Inference runs on Isolate via `InferenceIsolate.start()` → `.run()`
- Must call `.stop()` during app disposal to prevent memory leaks
- Confidence thresholds: 0.70 for display, 0.50 for data flywheel
- Blank frame detection prevents unnecessary inference

**Persistence:**
- Hive boxes: `hiveBoxDrawings`, `hiveBoxAssets`, `hiveBoxUsageLogs`
- See `lib/core/constants/app_constants.dart` for box names
- All models require TypeAdapter codegen (run `build_runner`)

**Routing:**
- Declarative routing via `go_router`
- Routes defined in `lib/presentation/routes/app_router.dart`
- Path-based: `/`, `/camera`, `/result`, `/history`, `/settings`

**Asset Management:**
- ML model bundled: `assets/ml_models/quickdraw_classifier_v1.tflite`
- 3D models downloaded from Firebase Storage → cached locally
- Audio files similarly cached after first download

**Testing Standards:**
- Use `mocktail` for mocking (not mockito)
- Use `bloc_test` package for BLoC testing
- Domain layer requires comprehensive coverage (≥90%)
- Firebase Emulator Suite for integration tests

## Common Pitfalls

**Initialization Order:** Violating Hive → DI order causes runtime crashes

**Build Runner:** Forgetting to regenerate after adding `@injectable` breaks DI at runtime

**Domain Purity:** Importing Flutter/Firebase into domain/ breaks layer isolation

**Isolate Lifecycle:** Not calling `InferenceIsolate.stop()` causes memory leaks

**Camera Permissions:** iOS requires `Info.plist` camera usage description; Android needs manifest permission

**Git Security:** Never commit `.env` or `google-services.json` (already in `.gitignore`)

## Documentation Standards

**When to Document:**
When implementing new features, architectural changes, or complex algorithms, create comprehensive documentation following academic textbook standards. Documentation is mandatory for:
- New architecture patterns or significant refactoring
- Complex state transitions or business logic flows
- ML/AI model changes or optimization techniques
- API integrations or external service configurations
- Performance optimization strategies
- Security implementations

**Documentation Structure (Academic Style):**

All technical documentation must follow this structure:

1. **Overview Section**
   - Clear problem statement
   - Objective and scope definition
   - Prerequisites and dependencies
   - Key terminology definitions

2. **Theoretical Foundation**
   - Conceptual explanation of the approach
   - Design principles and rationale
   - Comparison with alternative solutions
   - Trade-offs and decision factors

3. **Technical Specification**
   - Detailed architecture with Mermaid diagrams (mandatory)
   - Component breakdown and relationships
   - Data flow diagrams
   - State transition diagrams
   - Sequence diagrams for complex interactions

4. **Implementation Details**
   - Step-by-step implementation guide
   - Code examples with inline explanations
   - Configuration requirements
   - Integration points

5. **Validation & Testing**
   - Test strategy and coverage requirements
   - Example test cases
   - Performance benchmarks
   - Edge cases and error scenarios

6. **Operational Guidelines**
   - Deployment procedures
   - Monitoring and maintenance
   - Troubleshooting guide
   - Common pitfalls and solutions

**Mermaid Diagram Requirements:**

Every documentation file must include relevant diagrams using Mermaid.js v11:

```markdown
## Architecture Overview

\`\`\`mermaid
flowchart TB
    subgraph "Presentation Layer"
        UI[UI Components]
        Bloc[BLoC State Management]
    end
    
    subgraph "Domain Layer"
        UC[Use Cases]
        Entities[Domain Entities]
        RepoInterface[Repository Interfaces]
    end
    
    subgraph "Data Layer"
        RepoImpl[Repository Implementation]
        DataSource[Data Sources]
        Models[Data Models]
    end
    
    UI --> Bloc
    Bloc --> UC
    UC --> RepoInterface
    RepoImpl -.implements.-> RepoInterface
    RepoImpl --> DataSource
    Models --> Entities
\`\`\`
```

**Diagram Types by Context:**
- Architecture decisions → `flowchart` or `graph`
- State management → `stateDiagram-v2`
- Module interactions → `sequenceDiagram`
- Data models → `classDiagram` or `erDiagram`
- Project timeline → `gantt`
- User experience → `journey`

**Writing Standards:**

- **Language:** English for all technical content; Vietnamese only for UI strings
- **Tone:** Formal academic style, similar to IEEE or ACM publications
- **Precision:** Use exact technical terminology, avoid colloquialisms
- **Structure:** Hierarchical headings (H1 → H6), logical flow
- **Citations:** Reference external resources, RFCs, or papers when applicable
- **Code Examples:** Always include working, tested code snippets
- **Completeness:** Document all parameters, return types, exceptions, and side effects

**Template Reference:**

Follow patterns from `e:\AI_Docs\docs\copilot_skill\skills\`:
- **Mermaid diagrams:** See `mermaidjs-v11/SKILL.md` for syntax patterns
- **Technical writing:** Follow `docs-write/SKILL.md` for clarity
- **Architecture docs:** Reference `backend-development/SKILL.md` for structure
- **Security standards:** Apply `ENGINEERING_STANDARD.md` principles

**Knowledge Packaging Pattern:**

When creating comprehensive documentation, organize as a skill-like structure:

```
docs/
  {feature-name}/
    README.md              # Overview and quick start
    ARCHITECTURE.md        # System design with diagrams
    IMPLEMENTATION.md      # Step-by-step guide
    API_REFERENCE.md       # Detailed API documentation
    TROUBLESHOOTING.md     # Common issues and solutions
    references/            # Supporting materials
      diagrams/            # Mermaid source files
      examples/            # Working code samples
      benchmarks/          # Performance data
```

**Quality Checklist:**

Before finalizing documentation:
- [ ] All Mermaid diagrams render correctly
- [ ] Code examples compile and run without errors
- [ ] Technical accuracy verified against implementation
- [ ] Headings follow logical hierarchy
- [ ] Links to reference files are valid
- [ ] Spelling and grammar checked (US English)
- [ ] Consistent terminology throughout
- [ ] Academic tone maintained (no informal language)

## Reference Files

Key exemplars showing project patterns:
- Domain layer: [lib/domain/usecases/recognize_drawing_usecase.dart](../lib/domain/usecases/recognize_drawing_usecase.dart)
- Data layer: [lib/data/repositories/recognition_repository_impl.dart](../lib/data/repositories/recognition_repository_impl.dart)
- Presentation: [lib/presentation/bloc/recognition/recognition_bloc.dart](../lib/presentation/bloc/recognition/recognition_bloc.dart)
- DI setup: [lib/core/di/injection_container.dart](../lib/core/di/injection_container.dart)
- ML pipeline: [lib/data/ml/inference_isolate.dart](../lib/data/ml/inference_isolate.dart)
- State flows: [.github/state_machine.md](state_machine.md) — Complete state diagrams for all BLoCs and app lifecycle
