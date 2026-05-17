# 🚀 Phonics Journey

> A high-fidelity, **privacy-first**, **offline-only** phonics app aligned to the
> **Little Wandle Letters and Sounds Revised** programme.
> Built with Flutter for children aged 4–7.

[![CI/CD](https://github.com/fynes-forge/phonics-journey/actions/workflows/main.yml/badge.svg)](https://github.com/fynes-forge/phonics-journey/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.22-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Privacy: Offline Only](https://img.shields.io/badge/Privacy-Offline%20Only-green)](SECURITY.md)

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Economy & Rewards](#economy--rewards)
- [Curriculum](#curriculum)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Running Tests](#running-tests)
- [Building for Release](#building-for-release)
- [Parental Features](#parental-features)
- [Privacy](#privacy)
- [Contributing](#contributing)

---

## Overview

Phonics Journey takes children on a **space adventure** through 100 phonics levels,
each represented as a planet on a winding galaxy path. Children drag and drop letter
tiles to spell words, earning up to 3 stars per level. The 3-star gate ensures mastery
before progression — a child must achieve **100% accuracy** to unlock the next planet.

The app is built **offline-first**: no internet permission, no analytics,
no Firebase, no cloud syncing. All data lives on the device.

---

## Features

### 🌌 Planet Path UI

- Vertically scrolling, winding "Space Pathway" through a colourful galaxy
- Each level = a Planet with visual states: locked 🔒, in-progress, complete ⭐⭐⭐
- **Rocket Hero:** A player icon that "docks" at the top-left shoulder of the current active level
- Pulsating animation on the current level to guide the child's attention
- Profile colour tints the UI, glowing planet auras, and the Rocket's milestone-based hull

### 🎮 Spelling Game Engine

- Drag-and-drop letter tiles into word placeholders
- Tap a tile to auto-place; tap a filled slot to return the letter
- Distractor letters increase in number across phases (2 → 4 distractors)
- Immediate feedback with animated overlays and Star Coin rewards
- **Word Peek:** Long-press the word prompt to reveal a large emoji hint — `sat` shows 🪑, `frog` shows 🐸. Works fully offline with zero bundle impact.

### ⭐ Star Bank & Progression

- **Mastery Gate:** Level N+1 is hard-locked until Level N achieves 3 stars (100% accuracy)
- **Persistence:** All progress stored locally in Hive NoSQL — survives app restarts
- **The Bank:** A persistent Star counter in the Top Bar tracks lifetime mastery across all levels
- Best score per level is recorded across multiple attempts

### 🔊 Audio Engine (3-tier fallback)

1. **Bundled MP3 assets** — if present in `assets/audio/`
2. **TTS with phonetic mapping** — `s` → `"ssss"`, not `"ess"` (UK English, 0.4× rate)
3. **Parental custom recordings** — parent records their own voice per phoneme, stored on-device

### 🎨 Customisation

- 8 profile theme colours that tint the entire UI
- 8 avatar emojis
- Child's name displayed prominently throughout

### 🔒 Privacy

- Zero internet permissions
- No analytics, no tracking, no ads
- All data in Hive (local NoSQL) on device only

---

## Economy & Rewards

The app uses a **Passive Reward Loop** based on the child's total Star count.
Rewards unlock automatically as milestones are reached — no in-app purchases, no timers.

### 🚀 Rocket Milestones

| Star Count  | Rocket Colour | Rank Title |
|-------------|---------------|------------|
| 0–9 Stars   | Red Accent    | Cadet      |
| 10–29 Stars | Green Accent  | Explorer   |
| 30–59 Stars | Orange Accent | Captain    |
| 60+ Stars   | Purple Accent | Master     |

---

## Curriculum

100 levels aligned to **Little Wandle Letters and Sounds Revised**:

| Levels | Phase | Content |
|--------|-------|---------|
| 1–25   | 2     | Single GPCs: s, a, t, p, i, n, m, d, g, o, c, k, ck, e, u, r, h, b, f, l, ff, ll, ss, j, v |
| 26–55  | 3     | Digraphs: ch, sh, th, ng; vowel digraphs: ai, ee, igh, oa, oo, ar, or, ur, ow, oi, ear, air, ure, er; Tricky word sets 1–7 |
| 56–70  | 4     | Adjacent consonants: CVCC, CCVC, CCVCC; 3-letter blends; Phase 4 tricky words |
| 71–100 | 5     | Alternative spellings: ay, ou, ie, ea, oy, ir, ue, aw, wh, ph, ew, oe, au, ey; Split digraphs: a-e, e-e, i-e, o-e, u-e; Phase 5 tricky words |

---

## Tech Stack

| Concern          | Choice          | Reason |
|------------------|-----------------|--------|
| Framework        | Flutter 3.22    | Cross-platform, high-performance animations |
| State Management | flutter_bloc 8  | Predictable, testable, clean |
| Local Storage    | Hive            | Fast, offline NoSQL, no SQL overhead |
| Animation        | flutter_animate | Declarative, bouncy micro-interactions |
| Celebration      | lottie          | Lightweight confetti JSON animations |
| TTS              | flutter_tts     | UK English, adjustable rate/pitch |
| Audio SFX        | audioplayers    | Cross-platform local asset playback |
| Navigation       | go_router       | Declarative, deep-link ready |
| DI               | get_it          | Lightweight service locator |
| Font             | Andika          | Open source — b/d, p/q, I/l distinguishable |

---

## Project Structure

```
phonics_journey/
├── lib/
│   ├── core/
│   │   ├── constants/          # App-wide constants
│   │   ├── theme/              # AppTheme, colours, typography
│   │   └── router/             # GoRouter configuration
│   ├── data/
│   │   ├── datasources/        # HiveDatasource (local only)
│   │   ├── models/             # Hive-annotated models + adapters
│   │   └── repositories/       # Profile & Progress repositories
│   ├── domain/
│   │   └── usecases/           # GetCurriculum, ManageProfile, ManageProgress
│   ├── presentation/
│   │   ├── blocs/              # ProfileBloc, ProgressBloc, GameBloc
│   │   ├── screens/
│   │   │   ├── home/           # SplashScreen
│   │   │   ├── profile/        # ProfileSetupScreen
│   │   │   ├── level_map/      # PlanetPathScreen
│   │   │   ├── game/           # GameScreen (spelling engine)
│   │   │   └── settings/       # SettingsScreen, VoiceRecorderScreen
│   │   └── widgets/
│   │       ├── planet/         # PlanetNode widget
│   │       └── game/           # WordPeekCard, LetterTile
│   ├── services/
│   │   ├── audio_service.dart          # 3-tier audio (MP3 → TTS → custom)
│   │   ├── curriculum_service.dart     # JSON curriculum loader
│   │   └── emoji_dictionary_service.dart # Word → emoji lookup (642 mappings)
│   └── main.dart               # App entry, DI setup, Hive init
├── assets/
│   ├── fonts/                  # Andika-Regular.ttf, Andika-Bold.ttf
│   ├── audio/
│   │   ├── phonemes/           # Optional: s.mp3, a.mp3, ch.mp3 …
│   │   ├── words/              # Optional: sat.mp3, cat.mp3 …
│   │   └── sfx/                # correct.mp3, wrong.mp3, level_complete.mp3
│   ├── lottie/
│   │   └── confetti.json       # Celebration animation
│   └── images/                 # Splash logo, planet textures
├── curriculum.json             # Full 100-level curriculum data with emoji mappings
├── test/
│   ├── unit/                   # core_test.dart
│   └── widget/                 # planet_node_test.dart
├── .github/
│   ├── workflows/
│   │   ├── main.yml            # CI — analyse, test, debug APK on every push
│   │   └── release.yml         # Release — signed APK/AAB + GitHub Release on v* tags
│   ├── ISSUE_TEMPLATE/         # Bug, feature, and curriculum issue templates
│   ├── PULL_REQUEST_TEMPLATE/  # PR checklist including privacy gate
│   ├── CODEOWNERS              # Auto-assign reviews for sensitive paths
│   └── dependabot.yml          # Weekly dependency updates
├── README.md
├── CONTRIBUTING.md
├── RELEASE.md
└── SECURITY.md
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.22.0 ([install](https://flutter.dev/docs/get-started/install))
- Dart SDK ≥ 3.2.0 (bundled with Flutter)
- Android Studio / Xcode for device deployment
- Java 17+ for Android builds

### 1. Clone the repository

```bash
git clone https://github.com/fynes-forge/phonics-journey.git
cd phonics-journey
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate Hive adapters

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Add the Andika font

Download from [Google Fonts](https://fonts.google.com/specimen/Andika) or [SIL](https://software.sil.org/andika/):

```
assets/fonts/Andika-Regular.ttf
assets/fonts/Andika-Bold.ttf
assets/fonts/Andika-Italic.ttf
```

### 5. Add a Lottie confetti animation

Download a free confetti JSON from [LottieFiles](https://lottiefiles.com) and save as:

```
assets/lottie/confetti.json
```

### 6. Run the app

```bash
flutter run                  # connected device or emulator
flutter run -d chrome        # web
flutter run -d linux         # Linux desktop (requires gtk3-devel)
```

---

## Running Tests

```bash
# All tests
flutter test

# Unit tests only
flutter test test/unit/

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Building for Release

See [RELEASE.md](RELEASE.md) for full signing instructions, keystore management, and store submission checklists.

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

To cut a release, tag the commit and push — the release workflow fires automatically:

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## Parental Features

### Accessing Settings

The settings screen is protected by a **Parental Gate** to keep little fingers out of the menus:

1. Tap the **Settings icon** (⚙️) in the Top Bar
2. Solve the arithmetic problem in the dialog
3. Access Profile editing and Custom Voice Recording overrides

### Custom Voice Recordings

1. Access Parent Settings (see above)
2. Tap **"Custom Voice Recordings"**
3. Select the phoneme you want to override
4. Record your pronunciation and save

The recording replaces the TTS fallback for that sound throughout the app — useful if the system voice is mispronouncing a tricky phoneme, or if you want the child to hear a familiar voice.

> **Developer note:** Add the [`record`](https://pub.dev/packages/record) package and uncomment the microphone code in `voice_recorder_screen.dart` to enable recording.

---

## Privacy

Phonics Journey is designed to be the safest possible app for young children:

- ✅ **Zero internet permission** — not declared in `AndroidManifest.xml`
- ✅ **No analytics** — no Firebase, Crashlytics, Sentry, or similar
- ✅ **No advertising** — no ad SDKs of any kind
- ✅ **No cloud sync** — all data in local Hive boxes only
- ✅ **No personal data transmitted** — ever
- ✅ **Network security config** blocks all outbound connections at the OS level
- ✅ `android:allowBackup="false"` prevents system backup of app data

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development standards, how to add new levels, and audio asset specifications.

---

## Licence

MIT © 2026 Fynes Forge. See [LICENSE](LICENSE).

The **Andika** font is © SIL International, released under the [SIL Open Font Licence 1.1](https://scripts.sil.org/OFL).
