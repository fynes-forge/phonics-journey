import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _ttsReady = false;

  final Map<String, String> _customVoicePaths = {};

  Map<String, String> get customVoicePaths => Map.unmodifiable(_customVoicePaths);

  Future<void> init() async {
    // Enable TTS for Web and Mobile
    if (kIsWeb || (!io.Platform.isLinux && !io.Platform.isWindows)) {
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

    if (!kIsWeb) {
      await _loadCustomVoicePaths();
    }
  }

  // ── Phoneme playback ──────────────────────────────────────────────────────

  Future<void> speakPhoneme(String grapheme) async {
    // 1. Custom voice (Android/iOS only)
    if (!kIsWeb && _customVoicePaths.containsKey(grapheme)) {
      await _playFile(_customVoicePaths[grapheme]!);
      return;
    }

    // 2. Try MP3 Asset (Helper handles the path logic)
    bool success = await _playAssetViaBytes('audio/phonemes/$grapheme.mp3');

    // 3. Fallback to TTS
    if (!success && _ttsReady) {
      final phonetic = _phoneticMap[grapheme] ?? grapheme;
      await _tts.speak(phonetic);
    }
  }

  Future<void> speakWord(String word) async {
    bool success = await _playAssetViaBytes('audio/words/$word.mp3');
    if (!success && _ttsReady) {
      await _tts.speak(word);
    }
  }

  Future<void> segmentWord(String word, List<String> phonemes) async {
    for (final phoneme in phonemes) {
      await speakPhoneme(phoneme);
      await Future.delayed(Duration(milliseconds: kIsWeb ? 600 : 400));
    }
  }

  // ── SFX ───────────────────────────────────────────────────────────────────

  Future<void> playCorrect() => _playAssetViaBytes('audio/sfx/correct.mp3');
  Future<void> playWrong() => _playAssetViaBytes('audio/sfx/wrong.mp3');
  Future<void> playLevelComplete() => _playAssetViaBytes('audio/sfx/level_complete.mp3');
  Future<void> playStarEarned() => _playAssetViaBytes('audio/sfx/star.mp3');
  Future<void> playButtonTap() => _playAssetViaBytes('audio/sfx/tap.mp3');

  /// SMART HELPER: Solves the 'assets/assets/' issue on Web and ensures Android works.
  Future<bool> _playAssetViaBytes(String path) async {
    // Step A: Try the direct path (Commonly works on Web/Chrome)
    try {
      final ByteData data = await rootBundle.load(path);
      await _sfxPlayer.play(BytesSource(data.buffer.asUint8List()));
      return true;
    } catch (_) {
      // Step B: Try prefixing with 'assets/' (Commonly required on Android/iOS)
      try {
        final ByteData data = await rootBundle.load('$path');
        await _sfxPlayer.play(BytesSource(data.buffer.asUint8List()));
        return true;
      } catch (e) {
        // Step C: Total failure, trigger TTS fallback
        debugPrint("Asset $path not found in any location. Switching to TTS.");
        return false;
      }
    }
  }

  // ── Custom voice recording (Mobile Only) ────────────────────────────

  Future<String> getCustomRecordingPath(String phoneme) async {
    if (kIsWeb) return '';
    final dir = await getApplicationDocumentsDirectory();
    final customDir = io.Directory('${dir.path}/custom_voices');
    if (!await customDir.exists()) await customDir.create(recursive: true);
    return '${customDir.path}/${phoneme.replaceAll('/', '_')}.aac';
  }

  Future<void> saveCustomVoicePath(String phoneme, String filePath) async {
    if (kIsWeb) return;
    _customVoicePaths[phoneme] = filePath;
    await _persistCustomVoiceIndex();
  }

  Future<void> deleteCustomVoice(String phoneme) async {
    if (kIsWeb) return;
    final path = _customVoicePaths.remove(phoneme);
    if (path != null) {
      final f = io.File(path);
      if (await f.exists()) await f.delete();
    }
    await _persistCustomVoiceIndex();
  }

  Future<void> _loadCustomVoicePaths() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final indexFile = io.File('${dir.path}/custom_voices/index.txt');
      if (!await indexFile.exists()) return;
      final lines = await indexFile.readAsLines();
      for (final line in lines) {
        final parts = line.split('=');
        if (parts.length == 2) _customVoicePaths[parts[0]] = parts[1];
      }
    } catch (_) {}
  }

  Future<void> _persistCustomVoiceIndex() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final indexFile = io.File('${dir.path}/custom_voices/index.txt');
      final lines = _customVoicePaths.entries.map((e) => '${e.key}=${e.value}').join('\n');
      await indexFile.writeAsString(lines);
    } catch (_) {}
  }

  Future<void> _playFile(String path) async {
    if (kIsWeb || path.isEmpty) return;
    await _sfxPlayer.play(DeviceFileSource(path));
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  Future<void> stop() async {
    await _tts.stop();
    await _sfxPlayer.stop();
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _sfxPlayer.dispose();
  }

  final Map<String, String> _phoneticMap = {
    's': 'ssss', 'a': 'aah', 't': 'tuh', 'p': 'puh', 'i': 'ih', 'n': 'nnn',
    'm': 'mmm', 'd': 'duh', 'g': 'guh', 'o': 'oh', 'c': 'kuh', 'k': 'kuh',
    'ck': 'kuh', 'e': 'eh', 'u': 'uh', 'r': 'rrr', 'h': 'huh', 'b': 'buh',
    'f': 'fff', 'l': 'lll', 'ff': 'fff', 'll': 'lll', 'ss': 'ssss', 'j': 'juh',
    'v': 'vvv', 'w': 'wuh', 'x': 'ks', 'y': 'yuh', 'z': 'zzz', 'zz': 'zzz',
    'qu': 'kwuh', 'ch': 'chuh', 'sh': 'shhhh', 'th': 'thhh', 'ng': 'nng',
    'ai': 'ay', 'ee': 'eee', 'igh': 'eye', 'oa': 'oh', 'oo': 'ooo',
    'oo_short': 'uh-oh', 'ar': 'arr', 'or': 'orr', 'ur': 'err', 'ow': 'ow',
    'oi': 'oy', 'ear': 'eer', 'air': 'air', 'ure': 'yoor', 'er': 'err',
    'ay': 'ay', 'ou': 'ow', 'ie': 'eye', 'ea': 'eee', 'oy': 'oy',
    'ir': 'err', 'ue': 'yoo', 'aw': 'aw', 'wh': 'wuh', 'ph': 'fff',
    'ew': 'yoo', 'oe': 'oh', 'au': 'aw', 'ey': 'ee', 'a_e': 'ay',
    'e_e': 'ee', 'i_e': 'eye', 'o_e': 'oh', 'u_e': 'yoo',
  };
}