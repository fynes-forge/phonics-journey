import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Maps grapheme/GPC strings to their phonetic TTS pronunciation.
/// We use elongated phoneme sounds to avoid letter-naming.
const Map<String, String> _phoneticMap = {
  's': 'ssss',
  'a': 'aah',
  't': 'tuh',
  'p': 'puh',
  'i': 'ih',
  'n': 'nnn',
  'm': 'mmm',
  'd': 'duh',
  'g': 'guh',
  'o': 'oh',
  'c': 'kuh',
  'k': 'kuh',
  'ck': 'kuh',
  'e': 'eh',
  'u': 'uh',
  'r': 'rrr',
  'h': 'huh',
  'b': 'buh',
  'f': 'fff',
  'l': 'lll',
  'ff': 'fff',
  'll': 'lll',
  'ss': 'ssss',
  'j': 'juh',
  'v': 'vvv',
  'w': 'wuh',
  'x': 'ks',
  'y': 'yuh',
  'z': 'zzz',
  'zz': 'zzz',
  'qu': 'kwuh',
  'ch': 'chuh',
  'sh': 'shhhh',
  'th': 'thhh',
  'ng': 'nng',
  'ai': 'ay',
  'ee': 'eee',
  'igh': 'eye',
  'oa': 'oh',
  'oo': 'ooo',
  'oo_short': 'uh-oh',
  'ar': 'arr',
  'or': 'orr',
  'ur': 'err',
  'ow': 'ow',
  'oi': 'oy',
  'ear': 'eer',
  'air': 'air',
  'ure': 'yoor',
  'er': 'err',
  'ay': 'ay',
  'ou': 'ow',
  'ie': 'eye',
  'ea': 'eee',
  'oy': 'oy',
  'ir': 'err',
  'ue': 'yoo',
  'aw': 'aw',
  'wh': 'wuh',
  'ph': 'fff',
  'ew': 'yoo',
  'oe': 'oh',
  'au': 'aw',
  'ey': 'ee',
  'a_e': 'ay',
  'e_e': 'ee',
  'i_e': 'eye',
  'o_e': 'oh',
  'u_e': 'yoo',
};

class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _ttsReady = false;

  // Cache of custom voice recordings: phoneme -> file path
  final Map<String, String> _customVoicePaths = {};

  Future<void> init() async {
    // flutter_tts not supported on Linux desktop or web
    if (!kIsWeb && !Platform.isLinux) {
      try {
        await _tts.setLanguage('en-GB');
        await _tts.setSpeechRate(0.4);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.1);
        _ttsReady = true;
      } catch (_) {
        _ttsReady = false;
      }
    }
    await _loadCustomVoicePaths();
  }

  // ── Phoneme playback ──────────────────────────────────────────────────────

  Future<void> speakPhoneme(String grapheme) async {
    if (_customVoicePaths.containsKey(grapheme)) {
      await _playFile(_customVoicePaths[grapheme]!);
      return;
    }
    // On web: skip asset lookup entirely to avoid 404 errors — no MP3s bundled
    if (!kIsWeb) {
      final assetPath = 'assets/audio/phonemes/$grapheme.mp3';
      if (await _assetExists(assetPath)) {
        await _sfxPlayer.play(AssetSource('audio/phonemes/$grapheme.mp3'));
        return;
      }
    }
    if (_ttsReady) {
      final phonetic = _phoneticMap[grapheme] ?? grapheme;
      await _tts.speak(phonetic);
    }
    // On web without TTS: silently no-op — visual feedback still works
  }

  Future<void> speakWord(String word) async {
    if (!kIsWeb) {
      final assetPath = 'assets/audio/words/$word.mp3';
      if (await _assetExists(assetPath)) {
        await _sfxPlayer.play(AssetSource('audio/words/$word.mp3'));
        return;
      }
    }
    if (_ttsReady) {
      await _tts.speak(word);
    }
  }

  /// Speak each phoneme in a word segmented (e.g. "c-a-t" → speak c, a, t)
  Future<void> segmentWord(String word, List<String> phonemes) async {
    for (final phoneme in phonemes) {
      await speakPhoneme(phoneme);
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  // ── SFX ───────────────────────────────────────────────────────────────────

  Future<void> playCorrect() async {
    await _playAssetSfx('audio/sfx/correct.mp3');
  }

  Future<void> playWrong() async {
    await _playAssetSfx('audio/sfx/wrong.mp3');
  }

  Future<void> playLevelComplete() async {
    await _playAssetSfx('audio/sfx/level_complete.mp3');
  }

  Future<void> playStarEarned() async {
    await _playAssetSfx('audio/sfx/star.mp3');
  }

  Future<void> playButtonTap() async {
    await _playAssetSfx('audio/sfx/tap.mp3');
  }

  Future<void> _playAssetSfx(String assetPath) async {
    if (kIsWeb) return; // No bundled SFX on web yet — silent fallback
    if (await _assetExists(assetPath)) {
      await _sfxPlayer.play(AssetSource(assetPath));
    }
  }

  // ── Custom voice recording (Parental Override) ────────────────────────────

  Future<String> getCustomRecordingPath(String phoneme) async {
    if (kIsWeb) return '';
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/custom_voices/${phoneme.replaceAll('/', '_')}.aac';
  }

  Future<void> saveCustomVoicePath(String phoneme, String filePath) async {
    if (kIsWeb) return;
    _customVoicePaths[phoneme] = filePath;
    final dir = await getApplicationDocumentsDirectory();
    final indexFile = File('${dir.path}/custom_voices/index.txt');
    await indexFile.parent.create(recursive: true);
    final lines = _customVoicePaths.entries
        .map((e) => '${e.key}=${e.value}')
        .join('\n');
    await indexFile.writeAsString(lines);
  }

  Future<void> deleteCustomVoice(String phoneme) async {
    if (kIsWeb) return;
    final path = _customVoicePaths.remove(phoneme);
    if (path != null) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    await _persistCustomVoiceIndex();
  }

  Future<void> _loadCustomVoicePaths() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final indexFile = File('${dir.path}/custom_voices/index.txt');
      if (!await indexFile.exists()) return;
      final lines = await indexFile.readAsLines();
      for (final line in lines) {
        final parts = line.split('=');
        if (parts.length == 2) {
          _customVoicePaths[parts[0]] = parts[1];
        }
      }
    } catch (_) {}
  }

  Future<void> _persistCustomVoiceIndex() async {
    if (kIsWeb) return;
    final dir = await getApplicationDocumentsDirectory();
    final indexFile = File('${dir.path}/custom_voices/index.txt');
    final lines = _customVoicePaths.entries
        .map((e) => '${e.key}=${e.value}')
        .join('\n');
    await indexFile.writeAsString(lines);
  }

  Future<void> _playFile(String path) async {
    if (kIsWeb || path.isEmpty) return;
    await _sfxPlayer.play(DeviceFileSource(path));
  }

  Map<String, String> get customVoicePaths =>
      Map.unmodifiable(_customVoicePaths);

  // ── Utilities ─────────────────────────────────────────────────────────────

  Future<bool> _assetExists(String assetPath) async {
    // rootBundle.load() always needs the full 'assets/...' prefix.
    // AssetSource() must NOT have 'assets/' — Flutter adds it automatically.
    // This method receives paths WITHOUT 'assets/' and adds it for the check.
    try {
      final fullPath = assetPath.startsWith('assets/')
          ? assetPath
          : 'assets/$assetPath';
      await rootBundle.load(fullPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    await _sfxPlayer.stop();
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _sfxPlayer.dispose();
  }
}