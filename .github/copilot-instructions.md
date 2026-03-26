# Copilot Instructions for VELOX

VELOX is a mobile IDE for Android built with Flutter. It embeds Monaco Editor and xterm.js via WebViews, with a Kotlin PTY backend for terminal emulation.

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build debug APK (ARM64)
flutter build apk --debug --target-platform android-arm64

# Build release APK
flutter build apk --release --target-platform android-arm64
```

Lint is provided by `flutter_lints`. Run with:
```bash
flutter analyze
```

There is no test suite in this repo.

## Architecture

### Feature-based structure

Each feature lives in `lib/features/<name>/` and follows a 3-file pattern:

```
<name>_screen.dart    # UI widget (ConsumerWidget or ConsumerStatefulWidget)
<name>_provider.dart  # Riverpod state (StateNotifier + immutable state class)
<name>_webview.dart   # WebView bridge (editor and terminal only)
```

The six features are: `home`, `editor`, `terminal`, `files`, `ai`, `git`.

Core infrastructure is in `lib/core/`:
- `router/app_router.dart` — GoRouter with a `ShellRoute` and bottom nav (`MainShell`)
- `theme/app_theme.dart` — Single dark theme (Material 3)

### State management (Riverpod)

Use `StateNotifierProvider` with an immutable state class that has `copyWith`:

```dart
class EditorState {
  final List<EditorTab> tabs;
  final int activeIndex;
  const EditorState({this.tabs = const [], this.activeIndex = 0});
  EditorState copyWith({List<EditorTab>? tabs, int? activeIndex}) =>
      EditorState(tabs: tabs ?? this.tabs, activeIndex: activeIndex ?? this.activeIndex);
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) => EditorNotifier(),
);
```

- `ref.watch(provider)` to read state in `build()`
- `ref.read(provider.notifier)` to call mutations
- `ref.listen(provider, (prev, next) { })` for side effects

### Navigation (GoRouter)

Routes are declared in `app_router.dart`. The shell wraps all routes with `MainShell` (bottom nav). Add new top-level screens as `GoRoute` children of the `ShellRoute`.

### WebView ↔ Dart communication

Monaco Editor and xterm.js run inside `WebViewWidget`. Messages flow via named JavaScript channels:

```dart
// Dart side — receive from JS
JavascriptChannel(name: 'VeloxEditor', onMessageReceived: (msg) {
  final data = jsonDecode(msg.message);
  // handle data['type']
})

// JS side — send to Dart
VeloxEditor.postMessage(JSON.stringify({ type: 'change', content: '...' }));
```

Dart sends to JS via `controller.runJavaScript(...)`.

### Platform channels (Terminal)

The terminal PTY is implemented in Kotlin (`android/app/src/main/kotlin/com/velox/app/PtyPlugin.kt`):
- **Method channel** `com.velox.app/pty` — `startPty`, `write`, `resize`, `kill`
- **Event channel** `com.velox.app/pty_output` — streams terminal output bytes

The Dart wrapper is `lib/features/terminal/pty_service.dart`.

Shell resolution order: Termux bash (`/data/data/com.termux/files/usr/bin/bash`) → `/system/bin/sh`.

### Git operations

Git commands are run via `Process.run('sh', ['-c', 'git ...'])` in `git_commands.dart`. There is no libgit2 or plugin — all git interaction is through the shell.

### AI assistant

`ai_provider.dart` calls the OpenRouter API over HTTP. Before sending a request it builds a system context that includes the current editor file content and the last 50 lines of terminal history. The model and API key are stored in `SharedPreferences`.

## Conventions

### Naming
- Files and directories: `snake_case`
- Classes: `PascalCase`
- Methods, variables, private members: `camelCase` with leading `_` for private

### Widget choice
| Situation | Widget type |
|---|---|
| No state, no providers | `StatelessWidget` |
| Reads/watches Riverpod state | `ConsumerWidget` |
| Needs `initState`/`dispose` + Riverpod | `ConsumerStatefulWidget` / `ConsumerState` |

### Theme
The app uses a single dark theme — do not add a light theme. Use colors from `AppTheme` / `Theme.of(context).colorScheme` rather than hardcoded hex values. Key accent colors defined in `app_theme.dart`:
- Primary: cyan `0xFF00E5FF`
- Secondary: purple `0xFF7C3AED`
- Surface: `0xFF0D1117`
- Success / info / warning / danger: green / blue / orange / red

### Error handling
- Wrap file I/O, platform channel calls, and API calls in `try`/`catch`
- Surface errors to the user via `ScaffoldMessenger.of(context).showSnackBar`

### Assets
Monaco and xterm bundles live in `assets/monaco/` and `assets/xterm/`. Load them with:
```dart
controller.loadFlutterAsset('assets/monaco/monaco.html');
```
Both directories are declared under `flutter.assets` in `pubspec.yaml`. Add new asset directories there before referencing them in code.

## Android target
- `minSdk 21` (Android 5.0), `compileSdk / targetSdk 34` (Android 14)
- `namespace`: `com.velox.app`
- Release builds use debug signing (intentional for dev distribution)
- Required manifest permissions: `INTERNET`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`
