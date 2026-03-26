<div align="center">

# ⚡ VELOX

### Мобильная IDE для Android

[![Flutter](https://img.shields.io/badge/Flutter-3.29.2-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.38.4-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2021--34-3DDC84?style=flat-square&logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-purple?style=flat-square)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/OlehHavrilko/VELOX/build.yml?style=flat-square&label=CI)](https://github.com/OlehHavrilko/VELOX/actions)

**VELOX** — полноценная среда разработки прямо на вашем Android-устройстве.  
Редактор кода, настоящий терминал, файловый менеджер, Git и ИИ-ассистент — всё в одном приложении.

</div>

---

## ✨ Возможности

<table>
<tr>
<td width="50%">

### 📝 Редактор кода
- **Monaco Editor 0.45.0** — движок VS Code
- Подсветка синтаксиса для десятков языков
- Автоопределение языка по расширению файла
- Нумерация строк, фолдинг, перенос строк
- Управление вкладками для нескольких файлов
- Кастомная тёмная тема с акцентом на cyan/purple
- Вставка кода от ИИ прямо в позицию курсора

</td>
<td width="50%">

### 💻 Терминал
- Настоящий псевдо-терминал (PTY) на Kotlin
- Поддержка Bash и sh
- **Автоматическое определение Termux** — доступ к git, python, node и полному Linux-инструментарию
- Стриминг вывода через xterm.js 5.3.0
- Поддержка цветов, прокрутки, изменения размера

</td>
</tr>
<tr>
<td width="50%">

### 📁 Файловый менеджер
- Навигация по файловой системе устройства
- Открытие файлов напрямую в редакторе
- Создание новых файлов
- Полный доступ к хранилищу

</td>
<td width="50%">

### 🤖 ИИ-ассистент
- Модель **Llama 3.3 70B** (OpenRouter API)
- Автоматический контекст: текущий файл + вывод терминала
- Умные действия: `[INSERT_CODE]` и `[RUN_COMMAND]`
- API-ключ хранится локально в зашифрованном хранилище

</td>
</tr>
<tr>
<td width="50%">

### 🔀 Git-интеграция
- Открытие Git-репозиториев с устройства
- Просмотр веток и переключение между ними
- История коммитов и статус репозитория
- Отслеживание изменений файлов

</td>
<td width="50%">

### 🏠 Главный экран
- Быстрый доступ ко всем инструментам
- Нижняя навигационная панель
- Единая тёмная тема приложения

</td>
</tr>
</table>

---

## 🛠 Технологии

| Слой | Технология | Версия |
|------|-----------|--------|
| UI-фреймворк | Flutter / Dart | 3.29.2 / 3.38.4+ |
| Управление состоянием | flutter_riverpod | 2.5.1 |
| Навигация | go_router | 13.2.0 |
| Редактор кода | Monaco Editor (WebView) | 0.45.0 |
| Терминал (UI) | xterm.js (WebView) | 5.3.0 |
| Терминал (бэкенд) | Kotlin ProcessBuilder + Platform Channels | — |
| Работа с файлами | file_picker, permission_handler, path_provider | — |
| HTTP | http | 1.2.0 |
| Безопасное хранилище | flutter_secure_storage | 9.0.0 |
| ИИ | OpenRouter REST API (SSE streaming) | v1 |
| Сборка Android | Kotlin, Java 17, Gradle (Kotlin DSL) | — |

---

## 🏗 Архитектура

```
Flutter UI (Dart)
    │
    ├── Riverpod Providers ──── общее состояние между виджетами
    │
    ├── WebView (Monaco / xterm.js)
    │       │  JavaScript → Dart   через named JavascriptChannels
    │       └─ Dart → JavaScript   через runJavaScript()
    │
    ├── Platform Channels ──── Dart ↔ Kotlin (PTY)
    │       Method Channel  com.velox.app/pty          (startPty, write, resize, kill)
    │       Event Channel   com.velox.app/pty_output   (стрим вывода терминала)
    │
    └── HTTP ──── OpenRouter REST API (стриминг через SSE)
```

Каждый модуль следует единому трёхфайловому паттерну:

```
features/<name>/
├── <name>_screen.dart    # UI-виджет (ConsumerWidget / ConsumerStatefulWidget)
├── <name>_provider.dart  # Riverpod StateNotifier + иммутабельный стейт
└── <name>_webview.dart   # WebView-мост (только для editor и terminal)
```

---

## 📂 Структура проекта

```
VELOX/
├── lib/
│   ├── main.dart                          # Точка входа (ProviderScope + GoRouter)
│   ├── core/
│   │   ├── router/app_router.dart         # Маршруты и MainShell (нижняя навигация)
│   │   └── theme/app_theme.dart           # Тёмная тема (cyan #00E5FF / purple #7C3AED)
│   └── features/
│       ├── home/                          # Главный экран
│       ├── editor/                        # Monaco Editor + управление вкладками
│       ├── terminal/                      # xterm.js + PTY platform channel
│       ├── files/                         # Файловый браузер
│       ├── ai/                            # ИИ-ассистент (OpenRouter)
│       └── git/                           # Git-интеграция
├── assets/
│   ├── monaco/monaco.html                 # Фронтенд Monaco Editor
│   └── xterm/xterm.html                   # Фронтенд xterm.js
└── android/app/src/main/kotlin/com/velox/app/
    ├── MainActivity.kt                    # Android Activity Flutter
    └── PtyPlugin.kt                       # PTY (ProcessBuilder + EventChannel)
```

---

## 🚀 Быстрый старт

### Требования

- **Flutter 3.29.2** (stable channel)
- **Java 17**
- **Android SDK** API 21–34
- Android-устройство или эмулятор (рекомендуется ARM64)

### Установка и запуск

```bash
# Установить зависимости
flutter pub get

# Запустить на подключённом устройстве
flutter run

# Собрать debug APK (ARM64)
flutter build apk --debug --target-platform android-arm64

# Собрать release APK
flutter build apk --release --target-platform android-arm64
```

> **Примечание:** Monaco Editor и xterm.js загружаются с CDN при сборке через CI. Для офлайн-сборки скачайте файлы вручную и поместите в `assets/monaco/` и `assets/xterm/`.

---

## 🤖 Настройка ИИ-ассистента

1. Откройте вкладку **AI** в приложении.
2. Нажмите на иконку ключа и вставьте ваш [OpenRouter API ключ](https://openrouter.ai/keys).
3. Ключ сохраняется локально в зашифрованном хранилище и никуда не передаётся кроме запросов к OpenRouter.

По умолчанию используется бесплатная модель **`meta-llama/llama-3.3-70b-instruct:free`**.  
Модель можно изменить в `lib/features/ai/ai_provider.dart`.

---

## 🖥 Терминал и Termux

По умолчанию терминал использует `/system/bin/sh`.  
Если установлен [Termux](https://termux.dev), VELOX автоматически подключится к его окружению Bash — это даёт доступ к полноценному Linux-инструментарию: `git`, `python`, `node`, `gcc` и многому другому.

---

## 🔑 Разрешения Android

| Разрешение | Назначение |
|-----------|-----------|
| `INTERNET` | Запросы к ИИ-API и загрузка CDN-ресурсов |
| `READ_EXTERNAL_STORAGE` | Открытие файлов с устройства |
| `WRITE_EXTERNAL_STORAGE` | Сохранение файлов на устройство |
| `MANAGE_EXTERNAL_STORAGE` | Полный доступ к файловой системе |

---

## ⚙️ CI/CD

Сборка через GitHub Actions (`.github/workflows/build.yml`) запускается при каждом пуше в `main`:

1. Установка Java 17 и Flutter 3.29.2
2. Генерация Gradle wrapper
3. Загрузка CDN-ресурсов (xterm.js, Monaco Editor) в `assets/`
4. `flutter pub get`
5. Сборка debug APK (ARM64)
6. Публикация APK как артефакт workflow

---

## 📄 Лицензия

MIT © 2026 [OlehHavrilko](https://github.com/OlehHavrilko)
