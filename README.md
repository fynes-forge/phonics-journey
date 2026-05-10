# 🚀 Phonics Journey

> A high-fidelity, **privacy-first**, **offline-only** phonics app aligned to the
> **Little Wandle Letters and Sounds Revised** programme.
> Built with Flutter for children aged 4–7.

[![CI/CD](https://github.com/yourname/phonics_journey/actions/workflows/main.yml/badge.svg)](https://github.com/yourname/phonics_journey/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.22-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Privacy: Offline Only](https://img.shields.io/badge/Privacy-Offline%20Only-green)](docs/privacy.md)

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
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
- Pulsating animation on the current level to guide attention
- Profile colour tints the UI and glowing planet aura

### 🎮 Spelling Game Engine
- Drag-and-drop letter tiles into word placeholders
- Distractor letters increase in number across phases (2 → 4 distractors)
- Tap a tile to auto-place; tap a filled slot to return the letter
- Immediate feedback with animated overlays

### ⭐ 3-Star Gate
- Level N+1 is **hard-locked** until Level N achieves 3 stars (100% accuracy)
- Stars are persistent and survive app restarts
- Best score per level is recorded across multiple attempts

### 🔊 Audio Engine (3-tier fallback)
1. **Bundled MP3 assets** (if present in `assets/audio/`)
2. **TTS with phonetic mapping** — "s" → "ssss", not "ess" (UK English)
3. **Parental custom recordings** — parent can record their own voice per phoneme

### 👨‍👩‍👧 Parental Features
- Long-press profile avatar 3× → PIN dialog → Parental Settings
- Custom voice recorder to override any TTS phoneme sound
- Profile editing (name, colour, avatar)

### 🎨 Customisation
- 8 profile theme colours that tint the entire UI
- 8 avatar emojis
- Child's name displayed prominently

### 🔒 Privacy
- Zero internet permissions
- No analytics, no tracking, no ads
- All data in Hive (local NoSQL) on device

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

| Concern | Choice | Reason |
|---------|--------|--------|
| Framework | Flutter 3.22 | Cross-platform, high-performance animations |
| State Management | flutter_bloc 8 | Predictable, testable, clean |
| Local Storage | Hive | Fast, offline NoSQL, no SQL overhead |
| Animation | flutter_animate | Declarative, bouncy micro-interactions |
| Celebration | lottie | Lightweight confetti JSON animations |
| TTS | flutter_tts | UK English, adjustable rate/pitch |
| Audio SFX | audioplayers | Cross-platform local asset playback |
| Navigation | go_router | Declarative, deep-link ready |
| DI | get_it | Lightweight service locator |
| Font | Andika | Open source, b/d p/q I/l distinguishable |

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
│   │       └── planet/         # PlanetNode widget
│   ├── services/
│   │   ├── audio_service.dart  # 3-tier audio (MP3 → TTS → custom)
│   │   └── curriculum_service.dart # JSON curriculum loader
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
├── curriculum.json             # Full 100-level curriculum data
├── test/
│   ├── unit/                   # core_test.dart
│   └── widget/                 # planet_node_test.dart
├── .github/workflows/
│   └── main.yml                # CI/CD pipeline
├── README.md
├── CONTRIBUTING.md
└── RELEASE.md
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
git clone https://github.com/yourname/phonics_journey.git
cd phonics_journey
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

Download from [Google Fonts](https://fonts.google.com/specimen/Andika) or the
[SIL website](https://software.sil.org/andika/):

```
assets/fonts/Andika-Regular.ttf
assets/fonts/Andika-Bold.ttf
assets/fonts/Andika-Italic.ttf
```

### 5. Add a Lottie confetti animation

Download a free confetti JSON from [LottieFiles](https://lottiefiles.com)
(search "confetti") and save as:

```
assets/lottie/confetti.json
```

### 6. Run the app

```bash
# On a connected device or emulator
flutter run

# With verbose logging
flutter run -v
```

---

## Running Tests

```bash
# All tests
flutter test

# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Building for Release

See [RELEASE.md](RELEASE.md) for full signing instructions.

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## Parental Features

### Accessing Settings

The settings screen is hidden behind a parental gate to prevent children
from accidentally accessing it:

1. **Long-press** the profile avatar in the top-left of the Planet Path screen
2. Do this **3 times** in succession
3. Enter the **4-digit PIN** (default: `1234`)
4. You'll be taken to the Parent Settings screen

> ⚠️ Change the default PIN in `planet_path_screen.dart` → `_showParentalPinDialog()`
> before distributing to children.

### Custom Voice Recordings

1. Access Parent Settings (see above)
2. Tap **"Custom Voice Recordings"**
3. Select the phoneme you want to override
4. Tap the microphone button and record your pronunciation
5. Preview and save

> **Developer note:** Add the [`record`](https://pub.dev/packages/record) package
> and uncomment the recording code in `voice_recorder_screen.dart` to enable
> microphone access.

---

## Privacy

Phonics Journey is designed to be the safest possible app for young children:

- ✅ **Zero internet permission** — not declared in `AndroidManifest.xml`
- ✅ **No analytics** — no Firebase, Crashlytics, Sentry, or similar
- ✅ **No advertising** — no ad SDKs
- ✅ **No cloud sync** — all data in local Hive boxes
- ✅ **No personal data transmitted** — ever
- ✅ **Network security config** blocks all outbound connections
- ✅ **`android:allowBackup="false"`** prevents system backup of sensitive data

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development standards.

---

## Licence

MIT © 2024 Your Name. See [LICENSE](LICENSE).

The **Andika** font is © SIL International, released under the
[SIL Open Font Licence 1.1](https://scripts.sil.org/OFL).
