import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 0)
class ProfileModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int themeColorValue; // stored as int (Color.value)

  @HiveField(3)
  int avatarIndex;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int currentLevel; // highest unlocked level

  ProfileModel({
    required this.id,
    required this.name,
    required this.themeColorValue,
    this.avatarIndex = 0,
    required this.createdAt,
    this.currentLevel = 1,
  });

  ProfileModel copyWith({
    String? name,
    int? themeColorValue,
    int? avatarIndex,
    int? currentLevel,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      themeColorValue: themeColorValue ?? this.themeColorValue,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      createdAt: createdAt,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }
}
