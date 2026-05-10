import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile_model.dart';
import '../models/progress_model.dart';

class HiveDatasource {
  static const String _profilesBox = 'profiles';
  static const String _progressBox = 'progress';

  // ── Profile operations ────────────────────────────────────────────────────

  Box<ProfileModel> get _profiles => Hive.box<ProfileModel>(_profilesBox);
  Box<LevelProgressModel> get _progress =>
      Hive.box<LevelProgressModel>(_progressBox);

  Future<void> saveProfile(ProfileModel profile) async {
    await _profiles.put(profile.id, profile);
  }

  ProfileModel? getProfile(String id) => _profiles.get(id);

  List<ProfileModel> getAllProfiles() => _profiles.values.toList();

  Future<void> deleteProfile(String id) async {
    await _profiles.delete(id);
    // Also delete all progress for this profile
    final keys = _progress.keys
        .where((k) => (k as String).startsWith('${id}_'))
        .toList();
    await _progress.deleteAll(keys);
  }

  /// Returns the most recently used profile id, stored separately
  String? getActiveProfileId() {
    final box = Hive.box('settings');
    return box.get('activeProfileId') as String?;
  }

  Future<void> setActiveProfileId(String id) async {
    final box = Hive.box('settings');
    await box.put('activeProfileId', id);
  }

  // ── Progress operations ───────────────────────────────────────────────────

  String _progressKey(String profileId, int levelId) =>
      '${profileId}_$levelId';

  Future<void> saveProgress(LevelProgressModel progress) async {
    final key = _progressKey(progress.profileId, progress.levelId);
    await _progress.put(key, progress);
  }

  LevelProgressModel? getProgress(String profileId, int levelId) {
    return _progress.get(_progressKey(profileId, levelId));
  }

  List<LevelProgressModel> getAllProgressForProfile(String profileId) {
    return _progress.values
        .where((p) => p.profileId == profileId)
        .toList()
      ..sort((a, b) => a.levelId.compareTo(b.levelId));
  }

  // ── Settings (parental voice overrides, etc.) ─────────────────────────────

  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box('settings');
    await box.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box('settings');
    return box.get(key, defaultValue: defaultValue);
  }

  // ── Ensure settings box is open ───────────────────────────────────────────
  static Future<void> openSettingsBox() async {
    if (!Hive.isBoxOpen('settings')) {
      await Hive.openBox('settings');
    }
  }
}
