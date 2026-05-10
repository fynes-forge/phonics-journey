// GENERATED CODE - Hand-written adapter for LevelProgressModel

part of 'progress_model.dart';

class LevelProgressModelAdapter extends TypeAdapter<LevelProgressModel> {
  @override
  final int typeId = 1;

  @override
  LevelProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LevelProgressModel(
      profileId: fields[0] as String,
      levelId: fields[1] as int,
      stars: fields[2] as int,
      bestScore: fields[3] as int,
      attempts: fields[4] as int,
      lastPlayed: fields[5] as DateTime?,
      isUnlocked: fields[6] as bool,
      totalCorrect: fields[7] as int,
      totalAttempted: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LevelProgressModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.profileId)
      ..writeByte(1)
      ..write(obj.levelId)
      ..writeByte(2)
      ..write(obj.stars)
      ..writeByte(3)
      ..write(obj.bestScore)
      ..writeByte(4)
      ..write(obj.attempts)
      ..writeByte(5)
      ..write(obj.lastPlayed)
      ..writeByte(6)
      ..write(obj.isUnlocked)
      ..writeByte(7)
      ..write(obj.totalCorrect)
      ..writeByte(8)
      ..write(obj.totalAttempted);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
