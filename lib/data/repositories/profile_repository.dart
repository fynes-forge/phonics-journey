import '../datasources/hive_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final HiveDatasource _datasource;

  ProfileRepository(this._datasource);

  Future<void> saveProfile(ProfileModel profile) =>
      _datasource.saveProfile(profile);

  ProfileModel? getProfile(String id) => _datasource.getProfile(id);

  List<ProfileModel> getAllProfiles() => _datasource.getAllProfiles();

  Future<void> deleteProfile(String id) => _datasource.deleteProfile(id);

  String? getActiveProfileId() => _datasource.getActiveProfileId();

  Future<void> setActiveProfileId(String id) =>
      _datasource.setActiveProfileId(id);

  ProfileModel? getActiveProfile() {
    final id = getActiveProfileId();
    if (id == null) return null;
    return getProfile(id);
  }
}
