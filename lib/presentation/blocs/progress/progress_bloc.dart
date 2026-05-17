import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/progress_model.dart';
import '../../../domain/usecases/manage_progress.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class ProgressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAllProgress extends ProgressEvent {
  final String profileId;
  LoadAllProgress(this.profileId);
  @override
  List<Object?> get props => [profileId];
}

class RecordLevelAttempt extends ProgressEvent {
  final String profileId;
  final int levelId;
  final int correctAnswers;
  final int totalQuestions;

  RecordLevelAttempt({
    required this.profileId,
    required this.levelId,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  @override
  List<Object?> get props =>
      [profileId, levelId, correctAnswers, totalQuestions];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class ProgressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProgressInitial extends ProgressState {}

class ProgressLoading extends ProgressState {}

class ProgressLoaded extends ProgressState {
  final Map<int, LevelProgressModel> progressMap;
  final String profileId;

  ProgressLoaded({required this.progressMap, required this.profileId});

  /// The "Star Bank" - Total coins/stars earned across the entire journey
  int get totalStarCoins => progressMap.values.fold(0, (sum, p) => sum + p.stars);

  bool isUnlocked(int levelId) {
    if (levelId == 1) return true;
    final prev = progressMap[levelId - 1];
    // 3-star gate requirement for Little Wandle mastery
    return prev != null && prev.stars == 3;
  }

  int starsFor(int levelId) => progressMap[levelId]?.stars ?? 0;

  bool isComplete(int levelId) => (progressMap[levelId]?.stars ?? 0) == 3;

  @override
  List<Object?> get props => [profileId, progressMap, totalStarCoins];
}

class ProgressUpdated extends ProgressState {
  final LevelProgressModel updatedProgress;
  final Map<int, LevelProgressModel> progressMap;
  final String profileId;

  ProgressUpdated({
    required this.updatedProgress,
    required this.progressMap,
    required this.profileId,
  });

  int get totalStarCoins => progressMap.values.fold(0, (sum, p) => sum + p.stars);

  bool isUnlocked(int levelId) {
    if (levelId == 1) return true;
    final prev = progressMap[levelId - 1];
    return prev != null && prev.stars == 3;
  }

  @override
  List<Object?> get props => [profileId, updatedProgress, progressMap, totalStarCoins];
}

class ProgressError extends ProgressState {
  final String message;
  ProgressError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ManageProgress _manageProgress;

  ProgressBloc(this._manageProgress) : super(ProgressInitial()) {
    on<LoadAllProgress>(_onLoad);
    on<RecordLevelAttempt>(_onRecord);
  }

  Future<void> _onLoad(
      LoadAllProgress event, Emitter<ProgressState> emit) async {
    emit(ProgressLoading());
    try {
      // Ensure level 1 is always initialised via the domain layer
      await _manageProgress.initProfile(event.profileId);
      final list = _manageProgress.getAllProgress(event.profileId);
      final map = <int, LevelProgressModel>{
        for (final p in list) p.levelId: p,
      };
      emit(ProgressLoaded(progressMap: map, profileId: event.profileId));
    } catch (e) {
      emit(ProgressError(e.toString()));
    }
  }

  Future<void> _onRecord(
      RecordLevelAttempt event, Emitter<ProgressState> emit) async {
    try {
      // The domain layer calculates the stars and updates Hive
      final updated = await _manageProgress.recordAttempt(
        profileId: event.profileId,
        levelId: event.levelId,
        correctAnswers: event.correctAnswers,
        totalQuestions: event.totalQuestions,
      );

      // Refresh the full progress map to calculate new total star count
      final list = _manageProgress.getAllProgress(event.profileId);
      final map = <int, LevelProgressModel>{
        for (final p in list) p.levelId: p,
      };

      emit(ProgressUpdated(
        updatedProgress: updated,
        progressMap: map,
        profileId: event.profileId,
      ));
    } catch (e) {
      emit(ProgressError(e.toString()));
    }
  }
}