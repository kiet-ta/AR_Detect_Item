# Magic Doodle — State Machine

> All application states, transitions, and edge cases mapped to the Core User Flow from `spec.md`.

---

## 1. Application Lifecycle State Machine

```mermaid
stateDiagram-v2
    direction TB

    [*] --> AppColdStart

    state AppColdStart {
        [*] --> Initializing
        Initializing --> CheckingPermissions: Firebase initialized
        CheckingPermissions --> PermissionDenied: Camera denied
        CheckingPermissions --> CheckingConnectivity: Camera granted
        PermissionDenied --> CheckingPermissions: User retries

        CheckingConnectivity --> OnlineFirstLaunch: Online + First launch
        CheckingConnectivity --> OnlineReturning: Online + Assets cached
        CheckingConnectivity --> OfflineReady: Offline + Assets cached
        CheckingConnectivity --> OfflineNoAssets: Offline + No cache

        OnlineFirstLaunch --> AssetDownload
        OnlineReturning --> CameraReady: Skip download
        OfflineReady --> CameraReady: Use cached assets
        OfflineNoAssets --> BlockedScreen: Show "connect to Wi-Fi"
    }

    state AssetDownload {
        [*] --> DownloadingModels
        DownloadingModels --> DownloadingAudio: 3D models done
        DownloadingAudio --> CachingLocally: Audio done
        CachingLocally --> DownloadComplete: All cached to Hive
        DownloadingModels --> DownloadFailed: Network error
        DownloadingAudio --> DownloadFailed: Network error
        DownloadFailed --> DownloadingModels: Retry
    }

    AssetDownload --> CameraReady: Download complete
    BlockedScreen --> CheckingConnectivity: Retry tapped

    CameraReady --> CameraActive

    state CameraActive {
        [*] --> CameraLive
        note right of CameraLive
            Camera preview at device
            native FPS. UI thread
            remains unblocked.
        end note
    }

    CameraActive --> AIRecognition: Frame captured (3-5 FPS)
    CameraActive --> ParentSettings: Settings tapped
    CameraActive --> DrawingHistory: History tapped
    CameraActive --> AppBackgrounded: OS lifecycle

    ParentSettings --> CameraActive: Back
    DrawingHistory --> CameraActive: Back
    AppBackgrounded --> CameraActive: App resumed

    state AIRecognition {
        [*] --> PreProcessing
        PreProcessing --> RunningInference: Image normalized
        note right of RunningInference
            Runs on ISOLATE.
            Main thread stays at 60fps.
        end note
        RunningInference --> EvaluatingConfidence: Labels returned

        state EvaluatingConfidence {
            [*] --> HighConfidence: confidence ≥ 70%
            [*] --> LowConfidence: 50% ≤ confidence < 70%
            [*] --> VeryLowConfidence: confidence < 50%
        }

        HighConfidence --> ResultDisplay
        LowConfidence --> CameraActive: Ignore silently
        VeryLowConfidence --> DataFlywheel
    }

    state ResultDisplay {
        [*] --> Loading3DAsset
        Loading3DAsset --> Rendering3D: Asset found in cache
        Loading3DAsset --> AssetMissing: Not in cache
        AssetMissing --> Loading3DAsset: Fallback download
        Rendering3D --> PlayingAudio: 3D model visible
        PlayingAudio --> ResultIdle: Audio finished
        note right of Rendering3D
            3D model rotates.
            Bilingual audio plays:
            "Apple — Quả Táo"
        end note
    }

    ResultDisplay --> CameraActive: Child taps back / timeout
    ResultDisplay --> LogUsage: Session data recorded

    state DataFlywheel {
        [*] --> CapturingGrayscale
        CapturingGrayscale --> CompressingImage: Grayscale extracted
        CompressingImage --> SavingToHive: Compressed
        SavingToHive --> QueuedForSync: Tagged "needs_retraining"
        note left of QueuedForSync
            Stored locally.
            Uploaded when Wi-Fi
            is available.
        end note
    }

    DataFlywheel --> CameraActive: Continue scanning

    state BackgroundSync {
        [*] --> MonitoringConnectivity
        MonitoringConnectivity --> SyncingDrawings: Wi-Fi detected
        MonitoringConnectivity --> Idle: Still offline
        SyncingDrawings --> UploadingToStorage: Batch upload
        UploadingToStorage --> WritingMetadata: Files uploaded
        WritingMetadata --> SyncComplete: Firestore updated
        SyncComplete --> MonitoringConnectivity: Reset
        SyncingDrawings --> SyncFailed: Network lost mid-sync
        SyncFailed --> MonitoringConnectivity: Will retry
    }

    LogUsage --> BackgroundSync

    CameraActive --> [*]: App terminated
```

---

## 2. Camera BLoC State Machine

```mermaid
stateDiagram-v2
    [*] --> Uninitialized

    Uninitialized --> Initializing: InitCamera event
    Initializing --> Ready: Camera controller ready
    Initializing --> Error: Permission denied / Hardware error

    Ready --> Streaming: StartPreview event
    Streaming --> Paused: PauseCamera event
    Streaming --> Capturing: CaptureFrame event (3-5 FPS timer)
    Paused --> Streaming: ResumeCamera event

    Capturing --> Streaming: Frame sent to Recognition BLoC

    Streaming --> Disposing: DisposeCamera event
    Paused --> Disposing: DisposeCamera event
    Error --> Initializing: RetryInit event
    Disposing --> [*]
```

---

## 3. Recognition BLoC State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> PreProcessing: FrameReceived event
    PreProcessing --> Inferring: Image tensor ready

    state Inferring {
        direction LR
        [*] --> IsolateRunning
        note right of IsolateRunning: Runs on background Isolate
        IsolateRunning --> [*]: Labels returned
    }

    Inferring --> Recognized: confidence ≥ 70%
    Inferring --> Unrecognized: confidence < 50%
    Inferring --> Uncertain: 50% ≤ confidence < 70%
    Inferring --> InferenceError: Model error / timeout

    Recognized --> DisplayingResult: Load 3D asset
    DisplayingResult --> Idle: ResultDismissed event

    Unrecognized --> SavingForRetraining: DataFlywheel trigger
    SavingForRetraining --> Idle: Saved to Hive

    Uncertain --> Idle: Silently skip

    InferenceError --> Idle: Log error, continue
```

---

## 4. Sync BLoC State Machine

```mermaid
stateDiagram-v2
    [*] --> WaitingForNetwork

    WaitingForNetwork --> CheckingQueue: ConnectivityChanged (online)
    CheckingQueue --> WaitingForNetwork: Queue empty
    CheckingQueue --> Uploading: Items in queue

    Uploading --> UploadingDrawings: Failed drawings first
    UploadingDrawings --> UploadingLogs: Drawings done
    UploadingLogs --> SyncComplete: All uploaded

    SyncComplete --> WaitingForNetwork: Reset listener

    Uploading --> SyncFailed: Network lost
    SyncFailed --> WaitingForNetwork: Will retry on reconnect

    WaitingForNetwork --> CheckingAssetUpdates: Online + periodic check
    CheckingAssetUpdates --> DownloadingNewAssets: New assets available
    CheckingAssetUpdates --> WaitingForNetwork: No updates
    DownloadingNewAssets --> WaitingForNetwork: Cached locally
```

---

## 5. State Transition Summary Table

| From State           | Event / Trigger              | To State              | Side Effect                                |
| -------------------- | ---------------------------- | --------------------- | ------------------------------------------ |
| `AppColdStart`       | Firebase init done           | `CheckingPermissions` | Request camera permission                  |
| `CheckingConnectivity` | Online + first launch      | `AssetDownload`       | Begin downloading 3D models + audio        |
| `CameraLive`         | Timer tick (3-5 FPS)         | `PreProcessing`       | Capture frame, send to Isolate             |
| `Inferring`          | confidence ≥ 70%             | `Recognized`          | Fetch cached 3D asset                      |
| `Inferring`          | confidence < 50%             | `DataFlywheel`        | Save grayscale to Hive, tag for retraining |
| `Recognized`         | Asset loaded                 | `DisplayingResult`    | Render 3D model, play bilingual audio      |
| `DisplayingResult`   | Timeout / tap                | `CameraLive`          | Log usage session                          |
| `WaitingForNetwork`  | Wi-Fi connected              | `Uploading`           | Batch upload queued drawings               |
| `SyncComplete`       | All items uploaded           | `WaitingForNetwork`   | Reset queue, update Firestore metadata     |

---

## 6. Error Recovery Matrix

| Error Scenario              | Detection               | Recovery Strategy                                     |
| --------------------------- | ----------------------- | ----------------------------------------------------- |
| Camera permission denied    | OS callback             | Show friendly prompt, deep-link to Settings           |
| TFLite model load failure   | Exception in ModelLoader | Retry 3x → show "restart app" message                |
| Isolate crash during inference | Isolate error port   | Restart Isolate, skip current frame                   |
| Network lost during sync    | Connectivity stream     | Pause upload, re-queue items, retry on reconnect      |
| Hive DB corruption          | HiveError catch         | Clear corrupted box, re-download assets on next Wi-Fi |
| 3D asset missing from cache | FileNotFound exception  | Fall back to placeholder model, queue download        |
| Firebase quota exceeded     | FirebaseException       | Exponential backoff, alert parent via Settings        |
