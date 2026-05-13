import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:record/record.dart'; // Add this
import 'package:permission_handler/permission_handler.dart'; // Add this

import '../../../core/theme/app_theme.dart';
import '../../../services/audio_service.dart';

class VoiceRecorderScreen extends StatefulWidget {
  final String phoneme;
  const VoiceRecorderScreen({super.key, required this.phoneme});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen>
    with SingleTickerProviderStateMixin {
  late final AudioService _audio;
  late final AudioRecorder _recorder; // Initialize the recorder
  late AnimationController _pulseController;

  _RecordingState _state = _RecordingState.idle;
  bool _hasExistingRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _audio = GetIt.I<AudioService>();
    _recorder = AudioRecorder(); // Create instance
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final path = await _audio.getCustomRecordingPath(widget.phoneme);
    final exists = File(path).existsSync();
    if (mounted) {
      setState(() {
        _hasExistingRecording = exists;
        _recordingPath = path;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose(); // Clean up the recorder!
    super.dispose();
  }

  // --- Logic Improvements ---

  Future<void> _handleRecordTap() async {
    if (_state == _RecordingState.idle) {
      // 1. Check & Request Permissions (Critical for Pixel/Android)
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _showError('Microphone permission is required to record.');
        return;
      }

      try {
        final path = await _audio.getCustomRecordingPath(widget.phoneme);

        // Ensure directory exists
        final directory = Directory(path).parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // 2. Start Recording
        // AAC LC is highly compatible with both Android and iOS
        const config = RecordConfig(encoder: AudioEncoder.aacLc);

        await _recorder.start(config, path: path);

        setState(() {
          _state = _RecordingState.recording;
          _recordingPath = path;
        });
        _pulseController.repeat(reverse: true);
      } catch (e) {
        _showError('Failed to start recording: $e');
      }
    } else if (_state == _RecordingState.recording) {
      // 3. Stop Recording
      try {
        final path = await _recorder.stop();
        _pulseController.stop();

        if (path != null) {
          // Notify your audio service that a custom voice exists now
          await _audio.saveCustomVoicePath(widget.phoneme, path);

          setState(() {
            _state = _RecordingState.saved;
            _hasExistingRecording = true;
          });

          // Reset to idle after a brief "Saved" state
          Future.delayed(2.seconds, () {
            if (mounted) setState(() => _state = _RecordingState.idle);
          });
        }
      } catch (e) {
        _showError('Failed to save recording: $e');
        setState(() => _state = _RecordingState.idle);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.errorRed,
        content: Text(message, style: const TextStyle(fontFamily: 'Andika')),
      ),
    );
  }

  // ... (Rest of your UI code remains the same) ...

  @override
  Widget build(BuildContext context) {
    // Note: I'm keeping your UI exactly as is, but wiring up the logic.
    return Scaffold(
      body: Container(
        decoration: AppTheme.spaceBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.moonWhite),
                    ),
                    Expanded(
                      child: Text(
                        'Record "${widget.phoneme}" sound',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.cosmicTeal.withOpacity(0.6),
                          AppTheme.cosmicTeal.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(color: AppTheme.cosmicTeal, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        widget.phoneme,
                        style: const TextStyle(
                          fontFamily: 'Andika',
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.moonWhite,
                        ),
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.04, 1.04),
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    children: [
                      Text('🎙️ Recording Tips',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _tip('Speak clearly and at a normal pace'),
                      _tip('Say just the sound, not the letter name'),
                      _tip('E.g. for "s" say "ssss" not "ess"'),
                      _tip('Record in a quiet room'),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    _statusText,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: _statusColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _handleRecordTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _state == _RecordingState.recording ? 100 : 84,
                      height: _state == _RecordingState.recording ? 100 : 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _state == _RecordingState.recording
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                        boxShadow: [
                          BoxShadow(
                            color: (_state == _RecordingState.recording
                                    ? AppTheme.errorRed
                                    : AppTheme.successGreen)
                                .withOpacity(0.5),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _state == _RecordingState.recording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_hasExistingRecording) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _previewRecording,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Preview'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.cosmicTeal),
                            foregroundColor: AppTheme.cosmicTeal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteRecording,
                          icon: const Icon(Icons.delete_rounded),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.errorRed),
                            foregroundColor: AppTheme.errorRed,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper methods (keep yours) ---
  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: AppTheme.starYellow, fontSize: 16)),
          Expanded(
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.moonWhite.withOpacity(0.85)))),
        ],
      ),
    );
  }

  String get _statusText {
    switch (_state) {
      case _RecordingState.idle:
        return _hasExistingRecording
            ? '✅ Custom recording active\nTap mic to re-record'
            : 'Tap the mic to start recording';
      case _RecordingState.recording:
        return '🔴 Recording... tap stop when done';
      case _RecordingState.saved:
        return '✅ Recording saved!';
    }
  }

  Color get _statusColor {
    switch (_state) {
      case _RecordingState.recording:
        return AppTheme.errorRed;
      case _RecordingState.saved:
        return AppTheme.successGreen;
      default:
        return AppTheme.moonWhite;
    }
  }

  Future<void> _previewRecording() async {
    if (_recordingPath != null && File(_recordingPath!).existsSync()) {
      await _audio.speakPhoneme(widget.phoneme);
    }
  }

  Future<void> _deleteRecording() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.stardustBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete recording?',
            style: Theme.of(context).textTheme.titleLarge),
        content: Text(
            'This will remove your custom recording for "${widget.phoneme}".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _audio.deleteCustomVoice(widget.phoneme);
      if (mounted) {
        setState(() {
          _hasExistingRecording = false;
          _state = _RecordingState.idle;
        });
      }
    }
  }
}

enum _RecordingState { idle, recording, saved }
