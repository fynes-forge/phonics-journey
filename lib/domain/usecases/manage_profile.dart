import 'package:uuid/uuid.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';

class ManageProfile {
  final ProfileRepository _repo;
  final _uuid = const Uuid();

  ManageProfile(this._repo);

  Future<ProfileModel> createProfile({
    required String name,
    required int themeColorValue,
    int avatarIndex = 0,
  }) async {
    final profile = ProfileModel(
      id: _uuid.v4(),
      name: name,
      themeColorValue: themeColorValue,
      avatarIndex: avatarIndex,
      createdAt: DateTime.now(),
      currentLevel: 1,
    );
    await _repo.saveProfile(profile);
    await _repo.setActiveProfileId(profile.id);
    return profile;
  }

  Future<void> updateProfile(ProfileModel profile) =>
      _repo.saveProfile(profile);

  Future<void> deleteProfile(String id) => _repo.deleteProfile(id);

  ProfileModel? getActiveProfile() => _repo.getActiveProfile();

  List<ProfileModel> getAllProfiles() => _repo.getAllProfiles();

  Future<void> switchProfile(String id) => _repo.setActiveProfileId(id);
}
