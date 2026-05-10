# Project Overview

This project is a Flutter arcade game called Tap To Pests. The player starts from a splash/start screen, enters a timed game session, taps moving pests to score points, then sees a game-over overlay with retry and home actions. Scores are saved locally in SQLite through a small repository/use-case layer.

## Runtime Flow

1. `main.dart` initializes Flutter, locks orientation to portrait, initializes app bindings, then runs `TapToPestsApp`.
2. `TapToPestsApp` builds a `MaterialApp` and shows `MainScreenController` as the first screen.
3. `MainScreenController` controls which screen is visible using `AppState`.
4. `StartScreen` shows the start background and start button.
5. `GameScreen` starts a 30-second game automatically, spawns pests, tracks score/time, and saves the final score.
6. `PestWidget` renders each moving pest, handles tap feedback, and plays the hit animation.
7. Score persistence flows through `SaveScoreUseCase` -> `ScoreRepositoryImpl` -> `ScoreLocalDataSourceImpl` -> `DatabaseHelper`.

## Main Entry Files

| File | Purpose |
| --- | --- |
| `lib/main.dart` | App entry point. Initializes bindings, locks portrait mode, and runs the app. |
| `lib/app.dart` | Defines `TapToPestsApp`, the root `MaterialApp`, theme, and home widget. |
| `lib/main_bindings.dart` | Manual dependency setup for database, score use cases, repository, datasource, and feedback service. |
| `pubspec.yaml` | Declares Flutter dependencies and asset folders for images/audio. |

### `main.dart`

| Function | What it does |
| --- | --- |
| `main()` | Calls `WidgetsFlutterBinding.ensureInitialized()`, locks portrait orientation with `SystemChrome.setPreferredOrientations`, awaits `MainBindings.init()`, then starts `TapToPestsApp`. |

### `app.dart`

| Class/widget | What it does |
| --- | --- |
| `TapToPestsApp` | Root stateless widget. Creates the `MaterialApp`, disables debug banner, sets a Material 3 light theme, and loads `MainScreenController`. |

### `main_bindings.dart`

| Class/function | What it does |
| --- | --- |
| `MainBindings` | Holds app-wide singleton-like dependencies used by the UI. |
| `getScoresUseCase` | Static app-level access to score loading. Currently wired but not used by the visible UI. |
| `saveScoreUseCase` | Static app-level access to score saving. Used by `GameScreen` when the game ends. |
| `feedbackService` | Static access to sound/haptic feedback. Used by `PestWidget` on tap. |
| `init()` | Builds `DatabaseHelper`, `ScoreLocalDataSourceImpl`, `ScoreRepositoryImpl`, `GetScoresUseCase`, `SaveScoreUseCase`, then initializes `FeedbackService`. |

## Feature Structure

```text
lib/
  core/
    database/
    services/
  features/
    game/
      domain/entities/
      presentation/pages/
      presentation/widgets/
    score/
      data/datasources/
      data/models/
      data/repositories/
      domain/entities/
      domain/repositories/
      domain/usecases/
```

The project roughly follows a feature-first structure. The `game` feature contains UI and gameplay state. The `score` feature follows a cleaner layered structure with domain, data, repository, and use-case files.

## Game Feature

### Domain Entity

#### `lib/features/game/domain/entities/pest_model.dart`

| Class/property | What it does |
| --- | --- |
| `PestModel` | Data object for one pest on screen. |
| `id` | Unique pest id used for hit/removal lookup. |
| `alignment` | Base screen position as Flutter `Alignment`. |
| `startOffset` | Randomized offset value stored on the model. It is currently created during spawn but not used by `PestWidget`. |
| `size` | Render size for the pest. Defaults to `96.0`. |
| `color` | Pest body color. |
| `driftSpeedMultiplier` | Controls movement speed. Increased later in the game. |
| `isHit` | Mutable flag used to prevent double-scoring and delayed despawn conflicts. |

### Screen Controller

#### `lib/features/game/presentation/pages/main_screen_controller.dart`

| Class/function | What it does |
| --- | --- |
| `AppState` | Enum with `start`, `game`, and `pest3d` states. |
| `MainScreenController` | Stateful widget that swaps between screens without using named routes. |
| `_currentState` | Stores the active screen state. Defaults to `AppState.start`. |
| `_startGame()` | Sets state to `AppState.game`. Passed into `StartScreen`. |
| `_showPest3d()` | Sets state to `AppState.pest3d`. Currently not wired to any visible button. |
| `_showStart()` | Returns to the start screen. Passed into `GameScreen` and `Pest3dScreen`. |
| `build()` | Switches on `_currentState` and returns `StartScreen`, `GameScreen`, or `Pest3dScreen`. |

### Start Screen

#### `lib/features/game/presentation/pages/start_screen.dart`

| Widget/function | What it does |
| --- | --- |
| `StartScreen` | Stateless start page. Receives `onStartPressed` from `MainScreenController`. |
| `build()` | Draws `assets/images/startImgs.png` as a full-screen background and shows an image start button using `assets/images/startBtn.png`. Tapping the button starts the game. |

### Game Screen

#### `lib/features/game/presentation/pages/game_screen.dart`

This file contains the main playable game loop plus small helper widgets/painters for the game-over UI.

| Class/widget | What it does |
| --- | --- |
| `_ConfettiPiece` | Small immutable model used by the game-over confetti painter. |
| `_ConfettiPainter` | Custom painter that draws colored squares/ovals around the game-over card. |
| `_Score3DPainter` | Custom painter that renders the final score with layered shadow, gradient, and highlight. |
| `GameScreen` | Main gameplay screen. Receives `onQuitPressed` to go back home. |
| `_GameScreenState` | Owns timers, score, active pests, spawn rules, game-over state, and overlay animations. |
| `StartButton` | Reusable animated glossy button used for retry. |
| `_StartButtonState` | Tracks pressed state and scales/changes button gradient during tap. |

Important `GameScreen` state:

| Field | What it does |
| --- | --- |
| `_gameDurationSeconds` | Total play time. Current value: 30 seconds. |
| `_endPhaseSeconds` | Last phase duration where difficulty increases. Current value: 8 seconds. |
| `_score` | Current player score. Increases by one per successful pest tap. |
| `_gameTimeRemaining` | Countdown value shown in the HUD. |
| `_isGameRunning` | Enables/disables gameplay and controls game-over overlay visibility. |
| `_activePests` | List of pests currently visible on screen. |
| `_spawnTimer` | Repeating timer that triggers spawn waves. |
| `_gameCountdownTimer` | Repeating timer that decrements game time every second. |
| `_pulseController` | Animates the glow behind the final score. |
| `_overlayController` | Animates fade/scale for the game-over overlay. |

Important functions:

| Function | What it does |
| --- | --- |
| `initState()` | Creates animation controllers and starts the game immediately. |
| `dispose()` | Cancels timers and disposes animation controllers. |
| `_cleanupTimers()` | Cancels both spawn and countdown timers and clears timer references. |
| `_generateConfetti()` | Creates randomized confetti pieces outside the center card area. |
| `_startGame()` | Resets score/time/pests/overlay state, marks the game running, starts spawning, and starts countdown. |
| `_startGameCountdown()` | Runs a 1-second timer. Decrements time until zero, then calls `_endGame()`. |
| `_startSpawning()` | Spawns a difficulty-scaled number of pests, staggers them within the second, then schedules itself again. |
| `_elapsedSeconds` | Derived getter for elapsed game time. |
| `_isEndPhaseElapsed(int elapsed)` | Returns true during the final difficulty phase. |
| `_spawnCountForElapsed(int elapsed)` | Determines how many pests spawn per wave based on elapsed time. |
| `_deSpawnDurationForElapsed(int elapsed)` | Determines how long an unhit pest stays visible. Duration gets shorter later in the game. |
| `_driftSpeedMultiplierForElapsed(int elapsed)` | Determines pest movement speed. Speed increases after 18 seconds and again near the end. |
| `spawnPest()` | Creates a new `PestModel` with random position/color/speed, adds it to `_activePests`, and schedules removal if it is not hit. |
| `_handleHit(int id)` | Marks a pest as hit, increments score, and removes the pest after `PestWidget.hitSequenceDuration`. |
| `_endGame()` | Stops gameplay, cancels timers, shows overlay animations, generates confetti, and saves a non-zero score with `SaveScoreUseCase`. |
| `build()` | Renders background, HUD, active `PestWidget`s, and the game-over overlay with Retry/Home actions. |
| `_statLabel(String text, {bool isAlert = false})` | Builds HUD labels for score and time. Time turns red under 10 seconds. |

### Pest Widget

#### `lib/features/game/presentation/widgets/pest_widget.dart`

This file contains the tap target widget and several custom painters used to draw animated pests, hit effects, and particle bursts.

| Class/widget | What it does |
| --- | --- |
| `PestWidget` | Stateful tap target for one `PestModel`. Handles movement, tap detection, feedback, and hit animation. |
| `_PestWidgetState` | Owns ticker-based drift movement, hit controller, tap state, and visual state transitions. |
| `_SimplePestShape` | Stateless wrapper around a custom pest painter for the normal idle pest. |
| `BlobPest3dAnimatedPainter` | Main custom painter used for animated blob-style pest rendering. Draws body, wings, legs, face, antennae, highlights, and motion lines. |
| `_SquashPestShape` | Widget used during hit animation to show the pest squash/splat state. |
| `_Particle` | Widget for one burst particle emitted during a hit. |
| `_BlobPest3dPainter`, `_BlobCapsulePestPainter`, `_SplatPest3dPainter` | Additional custom painter variants for pest shapes and splat visuals. Some are alternate/prototype renderers. |
| `_SplatPalette` | Builds highlight/base/deep colors from a source pest color using HSL adjustments. |

Important functions:

| Function | What it does |
| --- | --- |
| `initState()` | Initializes random velocity, schedules first direction change, starts a ticker, and creates the hit animation controller. |
| `dispose()` | Disposes ticker and hit animation controller. |
| `_scheduleNextDirectionChange(Duration elapsed)` | Sets the next random time when the pest should alter drift direction. |
| `_changeDirection(Duration elapsed)` | Randomly adjusts velocity and clamps it to a max speed based on `driftSpeedMultiplier`. |
| `_onTick(Duration elapsed)` | Runs every frame through the ticker. Updates idle animation progress and adds velocity/jitter to drift offset. |
| `_executeInstantTapEffects()` | Runs on tap down. Prevents duplicate taps, triggers sound/haptic feedback, marks tapped, stops movement, starts hit animation, then calls the parent `onTap`. |
| `_phase(double value, double start, double end)` | Normalizes a sub-range of animation progress to `0.0..1.0`. |
| `_build3dBlobPest(Color color, double progress, double scale)` | Builds the first part of the hit animation using a blob pest painter. |
| `_buildParticleBurst(Color color, double progress)` | Builds a radial set of particles for the hit effect. |
| `_buildHitFrame(Color color)` | Chooses what to render during hit animation: blob expansion, squash state, particles, and fade. |
| `build()` | Aligns the pest on screen, applies drift, handles tap down, renders idle shake/scale animation or hit animation. |

Painter helper groups:

| Helper group | What it does |
| --- | --- |
| `_drawShadow` methods | Draw soft shadows under pests or splats. |
| `_drawWing` / `_drawFluffyWing` methods | Draw side wings with gradients and highlights. |
| `_drawLegs` methods | Draw animated legs using paths and sine-based motion. |
| `_drawBody` methods | Draw main pest body using capsule or splat paths and radial gradients. |
| `_drawFace`, `_drawEye`, `_drawAngryEye` methods | Draw eyes, highlights, mouth, and expression details. |
| `_drawAntennae` methods | Draw antenna curves and tip highlights. |
| `_drawMotionLines`, `_drawRedLines`, `_drawTaperedStroke` methods | Draw motion/accent lines around pest shapes. |
| `_inkSplatPath` methods | Generate irregular splat outlines from radial points. |
| `_buildEdgeBumps` methods | Add tiny bumps to eye/splat shapes for an organic look. |

### 3D Pest Prototype Screen

#### `lib/features/game/presentation/pages/pest_3d_screen.dart`

This file appears to be a visual prototype/demo area for custom-painted pest and sphere animations. `Pest3dScreen` exists in `MainScreenController`, but no visible UI currently calls `_showPest3d()`, so this screen is not reachable from the current start screen.

| Class/widget | What it does |
| --- | --- |
| `Pest3dScreen` | Scaffold with a dark background that displays `BlobPest3dAnimatedWidget`. |
| `BlobPest3dPainter` | Custom painter for a red animated pest shape. |
| `BlobPest3dAnimatedWidget` | Stateful widget that owns an animation controller and repaints the pest continuously. |
| `BlobPest3dAnimatedPainter` | Custom painter variant used by the animated widget. |
| `AnimatedSphere` | Model for sphere position, radius, color, animation delay, and optional connection target. |
| `_defaultAnimatedSpheres()` | Returns a fixed list of demo spheres used by sphere painters. |
| `SpheresCustomPainter` | Draws animated 3D-looking spheres and optional connecting lines. |
| `SplatToSpheresTransitionView` | Demo widget that animates a splat-to-spheres transition using `SplatToSpheresTransitionPainter`. |
| `AnimatedSpheresWidget` | Demo widget that paints animated spheres directly. |
| `_BlobPest3dPainter` | Additional pest painter variant with configurable color and size scaling. |

### Splat to Spheres Painter

#### `lib/features/game/presentation/pages/splatToSpheresTransitionPainter.dart`

| Class/function | What it does |
| --- | --- |
| `SplatToSpheresTransitionPainter` | Custom painter that blends three layers: fading splat, burst particles/shockwave, and fading-in spheres. |
| `_easeIn(double t)` | Cubic ease-in helper for transition timing. |
| `_easeOut(double t)` | Cubic ease-out helper for transition timing. |
| `paint(Canvas canvas, Size size)` | Draws spheres, burst effects, and splat in the correct order based on `transition`. |
| `_drawShockwave(...)` | Draws expanding blurred rings during the midpoint burst. |
| `_drawBurstParticles(...)` | Draws deterministic radial particles during the transition. |
| `_withOpacity(...)` | Uses `saveLayer` to render a drawing callback at partial opacity. |
| `_SplatPest3dPainter` | Local custom painter for the splat/pest layer used by the transition. |
| `_SplatPalette` | Generates highlight/bright/base/deep color variants for splat rendering. |

### Other Game Pages

#### `lib/features/game/presentation/pages/privacy_policy_screen.dart`

| Widget/function | What it does |
| --- | --- |
| `PrivacyPolicyScreen` | Stateless screen that shows a gradient background, back button, title, and scrollable `assets/images/privacy_policy_content.png`. Currently not wired into the main visible flow. |

#### `lib/features/game/presentation/pages/main_menu_screen.dart`

This file is fully commented out. It looks like an earlier main-menu implementation that used a full-screen background and tap-to-start behavior. It is not part of the compiled app in its current form.

## Score Feature

The score feature is organized as a small data/domain stack.

### Domain Layer

#### `lib/features/score/domain/entities/score_entity.dart`

| Class/property | What it does |
| --- | --- |
| `ScoreEntity` | Domain object for a saved score. |
| `id` | Optional database id. |
| `score` | Numeric score value. |
| `dateTime` | Timestamp for when the score was saved. |

#### `lib/features/score/domain/repositories/score_repository.dart`

| Interface/function | What it does |
| --- | --- |
| `ScoreRepository` | Abstract contract for score persistence. |
| `saveScore(ScoreEntity score)` | Saves one score. |
| `getScores()` | Loads saved scores. |

#### `lib/features/score/domain/usecases/save_score_usecase.dart`

| Class/function | What it does |
| --- | --- |
| `SaveScoreUseCase` | Application action for saving a score. |
| `execute(ScoreEntity score)` | Delegates score saving to `ScoreRepository.saveScore`. |

#### `lib/features/score/domain/usecases/get_scores_usecase.dart`

| Class/function | What it does |
| --- | --- |
| `GetScoresUseCase` | Application action for loading saved scores. |
| `execute()` | Delegates score loading to `ScoreRepository.getScores`. Currently initialized but not used by the UI. |

### Data Layer

#### `lib/features/score/data/models/score_model.dart`

| Class/function | What it does |
| --- | --- |
| `ScoreModel` | Data model that extends `ScoreEntity` and knows how to convert to/from database maps. |
| `ScoreModel.fromMap(Map<String, dynamic> map)` | Converts SQLite row data into a `ScoreModel`. Converts `dateTime` from milliseconds since epoch. |
| `toMap()` | Converts a score into a map suitable for SQLite insert. Converts `dateTime` to milliseconds since epoch. |

#### `lib/features/score/data/datasources/score_local_datasource.dart`

| Class/function | What it does |
| --- | --- |
| `ScoreLocalDataSource` | Abstract datasource contract for local score operations. |
| `ScoreLocalDataSourceImpl` | SQLite implementation of `ScoreLocalDataSource`. |
| `saveScore(ScoreModel score)` | Inserts a score into the `scores` table. |
| `getScores()` | Queries all scores ordered by highest score first and maps rows into `ScoreModel`. |

#### `lib/features/score/data/repositories/score_repository_impl.dart`

| Class/function | What it does |
| --- | --- |
| `ScoreRepositoryImpl` | Concrete repository that bridges domain entities to the local datasource. |
| `saveScore(ScoreEntity score)` | Converts `ScoreEntity` to `ScoreModel`, then saves through datasource. |
| `getScores()` | Returns datasource score models as domain `ScoreEntity` values. |

## Core Layer

### Database

#### `lib/core/database/database_helper.dart`

| Class/function | What it does |
| --- | --- |
| `DatabaseHelper` | Singleton helper for opening and managing the SQLite database. |
| `database` getter | Lazily opens `scores.db` once and returns the cached `Database`. |
| `_initDB(String filePath)` | Resolves the database path and opens SQLite with version 1. |
| `_createDB(Database db, int version)` | Creates the `scores` table with `id`, `score`, and `dateTime` columns. |
| `close()` | Closes the cached database connection. |

### Feedback Service

#### `lib/core/services/feedback_service.dart`

| Class/function | What it does |
| --- | --- |
| `FeedbackService` | Singleton service for tap sound and haptic/vibration feedback. |
| `init()` | Checks vibration support, initializes SoLoud, and loads `assets/audio/pest_pop.wav` into memory. |
| `triggerTapFeedback()` | Plays a short pest-pop sound, speeds it up slightly, schedules it to stop, then triggers haptics. |
| `_triggerHaptics()` | Uses `Vibration.vibrate` when a vibrator exists, otherwise falls back to `HapticFeedback.lightImpact`; also calls `selectionClick`. |
| `dispose()` | Releases loaded audio source, deinitializes SoLoud, and marks the service uninitialized. |

## Assets

| Path | Used for |
| --- | --- |
| `assets/images/startImgs.png` | Start screen full background. |
| `assets/images/startBtn.png` | Start button image on the start screen. |
| `assets/images/privacy_policy_content.png` | Privacy policy image content. |
| `assets/audio/pest_pop.wav` | Main tap sound loaded by `FeedbackService`. |
| `assets/audio/tap_sound.mp3` | Declared in `pubspec.yaml`; not currently used by the visible code. |
| Other `assets/images/*` files | Backgrounds, insect art, retry/privacy/start assets. Some are declared through the folder asset entry but are not currently referenced directly in code. |

## Current Navigation State

| Screen | Reachable today? | Notes |
| --- | --- | --- |
| `StartScreen` | Yes | Default screen. |
| `GameScreen` | Yes | Reached by tapping the start button. |
| `Pest3dScreen` | No visible entry point | Controller supports it, but `_showPest3d()` is not passed to an active button. |
| `PrivacyPolicyScreen` | No visible entry point | Screen exists but is not wired into `MainScreenController`. |
| `MainMenuScreen` | No | Entire file is commented out. |

## Data Flow Summary

### Tap and score flow

```text
Player taps PestWidget
  -> PestWidget._executeInstantTapEffects()
  -> FeedbackService.triggerTapFeedback()
  -> GameScreen._handleHit(id)
  -> score increments
  -> pest is removed after hit animation
```

### End game score saving flow

```text
GameScreen._endGame()
  -> SaveScoreUseCase.execute(ScoreEntity)
  -> ScoreRepositoryImpl.saveScore()
  -> ScoreLocalDataSourceImpl.saveScore()
  -> DatabaseHelper.database
  -> SQLite scores table
```

## Notes For New Developers

- The active game loop is timer-based and lives in `GameScreen`; start there for gameplay changes.
- Pest rendering and hit animation are concentrated in `PestWidget`; start there for pest appearance, movement, sound timing, and tap behavior.
- Score saving works, but score loading is not currently shown in the UI.
- Some files contain prototype or commented code, especially `pest_3d_screen.dart`, `splatToSpheresTransitionPainter.dart`, and `main_menu_screen.dart`.
- `MainBindings` is the current dependency injection point. There is no external DI framework or route manager.
- The project uses `sqflite`, `flutter_soloud`, `vibration`, `flutter_animate`, and `flutter_svg`.
