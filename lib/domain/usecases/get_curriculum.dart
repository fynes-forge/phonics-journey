import '../../services/curriculum_service.dart';

class GetCurriculum {
  final CurriculumService _service;
  GetCurriculum(this._service);

  List<CurriculumLevel> call() => _service.levels;

  CurriculumLevel? getLevel(int id) => _service.getLevelById(id);

  int get totalLevels => _service.totalLevels;
}
