import 'dart:convert';
import 'package:flutter/services.dart';

class CurriculumLevel {
  final int id;
  final int phase;
  final String title;
  final String gpc;
  final String phoneme;
  final String grapheme;
  final String exampleWord;
  final List<String> words;
  final List<String> trickyWords;
  final List<String> distractorLetters;
  final String description;
  final bool startsUnlocked;

  const CurriculumLevel({
    required this.id,
    required this.phase,
    required this.title,
    required this.gpc,
    required this.phoneme,
    required this.grapheme,
    required this.exampleWord,
    required this.words,
    required this.trickyWords,
    required this.distractorLetters,
    required this.description,
    this.startsUnlocked = false,
  });

  factory CurriculumLevel.fromJson(Map<String, dynamic> json) {
    return CurriculumLevel(
      id: json['id'] as int,
      phase: json['phase'] as int,
      title: json['title'] as String,
      gpc: json['gpc'] as String,
      phoneme: json['phoneme'] as String,
      grapheme: json['grapheme'] as String,
      exampleWord: json['example_word'] as String,
      words: List<String>.from(json['words'] as List),
      trickyWords: List<String>.from(json['tricky_words'] as List? ?? []),
      distractorLetters:
          List<String>.from(json['distractor_letters'] as List? ?? []),
      description: json['description'] as String,
      startsUnlocked: json['unlocked'] as bool? ?? false,
    );
  }

  bool get isTrickyWordLevel => phoneme == 'tricky';
  bool get isReviewLevel => phoneme == 'review';
}

class CurriculumService {
  List<CurriculumLevel> _levels = [];
  bool _loaded = false;

  List<CurriculumLevel> get levels => List.unmodifiable(_levels);

  Future<void> loadCurriculum() async {
    if (_loaded) return;
    final jsonString = await rootBundle.loadString('curriculum.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final levelsList = data['levels'] as List;
    _levels = levelsList
        .map((e) => CurriculumLevel.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  CurriculumLevel? getLevelById(int id) {
    try {
      return _levels.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CurriculumLevel> getLevelsByPhase(int phase) =>
      _levels.where((l) => l.phase == phase).toList();

  int get totalLevels => _levels.length;
}
