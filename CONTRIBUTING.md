# Contributing to Phonics Journey

Thank you for helping improve Phonics Journey! This document covers
development standards, architecture decisions, and how to add new content.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Code Style](#code-style)
- [State Management Conventions](#state-management-conventions)
- [Adding New Levels](#adding-new-levels)
- [Adding Audio Assets](#adding-audio-assets)
- [Adding Lottie Animations](#adding-lottie-animations)
- [Privacy Rules](#privacy-rules)
- [Testing Requirements](#testing-requirements)
- [Pull Request Checklist](#pull-request-checklist)

---

## Architecture Overview

The project follows **Clean Architecture** with three layers:

```
Presentation  →  Domain  →  Data
(BLoC/Widgets)   (Use Cases)  (Repositories/Datasources)
```

### Dependency direction
`Presentation` depends on `Domain`. `Domain` is pure Dart (no Flutter imports).
`Data` implements the interfaces/use-cases defined in `Domain`.

### Service Locator
`GetIt` is used for DI. All registrations live in `main.dart` → `_setupDependencies()`.
**Never** use `GetIt.I<>()` inside widget `build()` methods — inject at the screen level.

---

## Code Style

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guide.
- Run `dart format .` before committing.
- Run `flutter analyze` — no warnings allowed on `main`.
- Maximum line length: **120 characters**.
- Always use **named parameters** for constructors with ≥ 3 arguments.
- Prefer `const` constructors wherever possible.

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | UpperCamelCase | `PlanetNode` |
| Files | snake_case | `planet_node.dart` |
| Variables | lowerCamelCase | `themeColor` |
| Constants | lowerCamelCase | `_planetSpacing` |
| BLoC events | Noun + Verb | `LoadActiveProfile` |
| BLoC states | Noun + Adjective | `ProfileLoaded` |

### Flutter-specific

- Screens live in `presentation/screens/`.
- Reusable widgets in `presentation/widgets/`.
- Each screen manages its own BLoC lifecycle (`close()` in `dispose()`).
- Use `BlocProvider.value` when passing an already-created BLoC down the tree.

---

## State Management Conventions

### BLoC pattern
Every feature has an `Event`, `State`, and `Bloc` in the same file under
`presentation/blocs/<feature>/`.

```dart
// ✅ Correct — explicit event naming
bloc.add(LoadActiveProfile());

// ❌ Wrong — don't pass raw data as unnamed constructor args
bloc.add(SomeEvent(rawString));
```

### Listening vs Building
- `BlocListener` for side-effects (navigation, snackbars, audio).
- `BlocBuilder` for UI rebuilds.
- `BlocConsumer` when both are needed in the same widget.

---

## Adding New Levels

All levels are defined in **`curriculum.json`** at the project root.
Do not hard-code level data in Dart files.

### JSON schema for a level

```jsonc
{
  "id": 101,              // integer, must be unique and sequential
  "phase": 5,             // 2 | 3 | 4 | 5
  "title": "wh – wheel",  // short display title
  "gpc": "wh",            // grapheme-phoneme correspondence key (matches audio file name)
  "phoneme": "w",         // IPA or simplified phoneme string
  "grapheme": "wh",       // displayed on the planet label
  "example_word": "wheel",
  "words": ["whale", "wheat", "wheel", "when", "white"],  // 3–7 words
  "tricky_words": [],      // optional sight words to show alongside
  "distractor_letters": ["w", "h", "ch", "sh"],  // wrong letters to include in tiles
  "description": "Alternative spelling for /w/: 'wh' as in wheel",
  "unlocked": false        // only set true for level 1
}
```

### Rules

- `id` must be sequential (no gaps).
- `words` should be decodable using phonics taught up to and including this phase.
- `distractor_letters` should include visually or phonemically similar letters.
- For Phase 3+, always include at least 3 distractors.
- Tricky word levels use `"phoneme": "tricky"` — this changes the game UI.

---

## Adding Audio Assets

### Phoneme sounds

Place MP3 files in `assets/audio/phonemes/`:

```
assets/audio/phonemes/s.mp3      # "ssss" sound
assets/audio/phonemes/ch.mp3     # "ch" sound
assets/audio/phonemes/igh.mp3    # "eye" sound
assets/audio/phonemes/a_e.mp3    # split digraph a-e (use underscore for /)
```

The file name must match the `gpc` key in `curriculum.json` exactly.
Use underscores for GPCs with special characters (e.g. `oo_short.mp3`).

### Word audio

Place MP3 files in `assets/audio/words/`:

```
assets/audio/words/sat.mp3
assets/audio/words/chin.mp3
```

The file name must be the lowercase word exactly.

### SFX

| File | Used for |
|------|---------|
| `assets/audio/sfx/correct.mp3` | Correct answer |
| `assets/audio/sfx/wrong.mp3` | Incorrect answer |
| `assets/audio/sfx/level_complete.mp3` | Level completion celebration |
| `assets/audio/sfx/star.mp3` | Individual star earned |
| `assets/audio/sfx/tap.mp3` | Button/tile tap |

### Audio specifications

- Format: **MP3**, mono, 44.1 kHz, 128 kbps
- Duration: phonemes ≤ 1 s, words ≤ 2 s, SFX ≤ 3 s
- Normalise to **-3 dB** peak

### Updating pubspec.yaml

After adding new folders, ensure the directory is listed:

```yaml
flutter:
  assets:
    - assets/audio/phonemes/
    - assets/audio/words/
    - assets/audio/sfx/
```

---

## Adding Lottie Animations

Place `.json` files in `assets/lottie/`. Reference them in code:

```dart
Lottie.asset(
  'assets/lottie/my_animation.json',
  repeat: false,
  errorBuilder: (_, __, ___) => const SizedBox(), // always provide fallback
)
```

**Always add an `errorBuilder`** — animations are decorative and must not crash
if the JSON is missing.

---

## Privacy Rules

These are **non-negotiable** and enforced by CI:

1. **No internet permission** in `AndroidManifest.xml`
2. **No `http` / `dio` / `retrofit`** packages in `pubspec.yaml`
3. **No Firebase** packages (`firebase_core`, etc.)
4. **No analytics** packages (`mixpanel_flutter`, `amplitude_flutter`, etc.)
5. **No ad SDKs** (`google_mobile_ads`, etc.)
6. **No cloud storage** packages (`cloud_firestore`, `supabase`, etc.)

If a feature requires network access (e.g., downloading font updates),
open a Discussion before implementing.

---

## Testing Requirements

### Minimum coverage targets

| Layer | Target |
|-------|--------|
| Domain use-cases | 90% |
| BLoC (events → states) | 85% |
| Repositories | 80% |
| Widgets | 60% |

### Writing tests

```dart
// Unit test template
test('description of expected behaviour', () {
  // Arrange
  final model = LevelProgressModel(...);
  // Act
  final result = model.calculateStars(5, 5);
  // Assert
  expect(result, 3);
});

// BLoC test template
test('emits [Loading, Loaded] on LoadActiveProfile', () async {
  bloc.add(LoadActiveProfile());
  await expectLater(
    bloc.stream,
    emitsInOrder([isA<ProfileLoading>(), isA<ProfileLoaded>()]),
  );
});
```

---

## Pull Request Checklist

Before opening a PR, ensure:

- [ ] `dart format .` passes with no changes
- [ ] `flutter analyze` has zero warnings
- [ ] All existing tests pass (`flutter test`)
- [ ] New code has appropriate tests
- [ ] New curriculum levels follow the JSON schema
- [ ] New audio files meet the specifications
- [ ] No internet/analytics packages added
- [ ] `RELEASE.md` updated if build process changed
- [ ] PR description explains what and why (not just what)

---

## Getting Help

Open a [GitHub Issue](https://github.com/yourname/phonics_journey/issues)
with the `question` label.
