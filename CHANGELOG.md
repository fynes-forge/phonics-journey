# Changelog

All notable changes to Phonics Journey will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Initial project scaffold

---

## [1.0.0] — 2026-01-01

### Added
- 100-level Little Wandle Letters and Sounds Revised curriculum (Phases 2–5)
- Planet Path scrolling level map with winding galaxy design
- Drag-and-drop spelling engine with distractor letters
- 3-star gate system (100% accuracy required to unlock next level)
- Three-tier audio engine: bundled MP3 → TTS phonetic mapping → parental override
- Profile setup with name, avatar (8 options), and theme colour (8 colours)
- Parental settings gate (long-press × 3 + PIN)
- Custom voice recorder screen for phoneme overrides
- Hive local storage — fully offline, no internet permission
- Andika font for b/d, p/q, I/l disambiguation
- Lottie confetti celebration on 3-star completion
- CI/CD pipeline (analyse → test → debug APK → release APK/AAB → iOS)
- GitHub Actions release workflow with auto-changelog
- Full documentation: README, CONTRIBUTING, RELEASE

### Privacy
- Zero internet permissions
- No analytics, no Firebase, no ads, no cloud sync
- Network security config blocks all outbound connections

---

<!-- Link definitions (update URLs for your repo) -->
[Unreleased]: https://github.com/fynesforge/phonics_journey/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/fynesforge/phonics_journey/releases/tag/v1.0.0
