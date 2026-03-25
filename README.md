# VELOX — Mobile IDE for Android

VELOX is a fully-featured integrated development environment that runs directly on Android devices. It brings together a syntax-aware code editor, a real terminal emulator, a file browser, and an AI coding assistant — all in one app.

---

## Features

- **Code Editor** — Monaco Editor (the engine behind VS Code) embedded in a WebView with syntax highlighting for dozens of languages and automatic language detection from the file extension.
- **Terminal** — A real pseudo-terminal backed by a native Kotlin plugin. Launches a Bash or sh shell (with Termux support when installed) and streams I/O through xterm.js.
- **File Browser** — Navigate the device file system, open directories, create and open files directly in the editor.
- **AI Assistant** — Chat with a Llama 3.3 70B model (via OpenRouter) that automatically receives the current file and recent terminal output as context, so it always knows what you are working on.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter 3.29.2 / Dart 3.38.4+ |
| State management | flutter_riverpod 2.5.1 |
| Navigation | go_router 13.2.0 |
| Code editor | Monaco Editor 0.45.0 (WebView) |
| Terminal UI | xterm.js 5.3.0 (WebView) |
| Terminal backend | Kotlin `ProcessBuilder` + Flutter Platform Channels |
| File access | file_picker, permission_handler, path_provider |
| AI backend | OpenRouter API (`meta-llama/llama-3.3-70b-instruct:free`) |
| Android build | Kotlin, Java 17, Gradle |

---

## Project Structure

```
velox/
├── lib/
│   ├── main.dart                   # App entry point (ProviderScope + GoRouter)
│   ├── core/
│   │   ├── router/app_router.dart  # Route definitions and MainShell (bottom nav)
│   │   └── theme/app_theme.dart    # Dark theme with cyan/purple accents
│   └── features/
│       ├── home/                   # Landing screen with quick-access buttons
│       ├── editor/                 # Monaco Editor integration + tab management
│       ├── terminal/               # xterm.js + PTY platform channel
│       ├── files/                  # Directory tree and file picker
│       └── ai/                     # OpenRouter chat UI and state
├── assets/
│   ├── monaco/monaco.html          # Monaco Editor page loaded by WebView
│   └── xterm/xterm.html            # xterm.js page loaded by WebView
└── android/app/src/main/kotlin/com/velox/app/
    ├── MainActivity.kt             # Flutter Android activity
    └── PtyPlugin.kt                # PTY implementation (ProcessBuilder + EventChannel)
```

Each feature follows the same three-file pattern:

```
features/<name>/
├── <name>_screen.dart    # Widget / UI
├── <name>_provider.dart  # Riverpod StateNotifier
└── <name>_webview.dart   # WebView bridge (editor and terminal only)
```

---

## Architecture

```
Flutter UI (Dart)
    │
    ├── Riverpod Providers ──── shared state across widgets
    │
    ├── WebView (Monaco / xterm.js)
    │       │  JavaScript → Dart  via named JavascriptChannels
    │       └─ Dart → JavaScript  via evaluateJavascript()
    │
    ├── Platform Channels ──── Dart ↔ Kotlin
    │       Method Channel  com.velox.app/pty   (startPty, write, resize, kill)
    │       Event Channel   com.velox.app/pty_output  (terminal output stream)
    │
    └── HTTP (http package) ──── OpenRouter REST API
```

---

## Getting Started

### Requirements

- Flutter **3.29.2** (stable channel)
- Java **17**
- Android SDK with **API 21–34**
- An Android device or emulator (ARM64 recommended for the prebuilt APK)

### Build and run

```bash
# Install dependencies
flutter pub get

# Run on a connected device
flutter run

# Build a debug APK
flutter build apk --debug --target-platform android-arm64
```

> **Note:** The Monaco Editor and xterm.js assets are fetched from a CDN during the CI build. For a fully offline build, download the files manually and place them in `assets/monaco/` and `assets/xterm/` respectively.

---

## AI Assistant Setup

1. Open the AI tab in VELOX.
2. Tap the key icon and paste your [OpenRouter API key](https://openrouter.ai/keys).
3. The key is stored locally with `SharedPreferences` and never leaves the device except in requests to OpenRouter.

The assistant uses the free **meta-llama/llama-3.3-70b-instruct** model. Any other model available on OpenRouter can be substituted by changing `_model` in `lib/features/ai/ai_provider.dart`.

---

## Terminal and Termux

VELOX's terminal uses Android's `/system/bin/sh` by default. If [Termux](https://termux.dev) is installed, it automatically detects and uses the Termux Bash environment, giving access to a full Linux toolchain (git, python, node, etc.) on the device.

---

## Permissions

The app requests the following Android permissions:

| Permission | Purpose |
|---|---|
| `INTERNET` | AI assistant API calls and CDN assets |
| `READ_EXTERNAL_STORAGE` | Opening files from device storage |
| `WRITE_EXTERNAL_STORAGE` | Saving files to device storage |
| `MANAGE_EXTERNAL_STORAGE` | Full file system access for the file browser |

---

## CI/CD

The GitHub Actions workflow (`.github/workflows/build.yml`) triggers on every push to `main` and:

1. Sets up Java 17 and Flutter 3.29.2.
2. Generates the Gradle wrapper.
3. Downloads CDN assets (xterm.js, Monaco Editor) into `assets/`.
4. Runs `flutter pub get`.
5. Builds a debug ARM64 APK.
6. Uploads the APK as a workflow artifact.

---

## License

MIT © 2026 OlehHavrilko
