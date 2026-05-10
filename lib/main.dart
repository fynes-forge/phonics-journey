import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/hive_datasource.dart';
import 'data/models/profile_model.dart';
import 'data/models/progress_model.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'domain/usecases/get_curriculum.dart';
import 'domain/usecases/manage_profile.dart';
import 'domain/usecases/manage_progress.dart';
import 'presentation/blocs/profile/profile_bloc.dart';
import 'presentation/blocs/progress/progress_bloc.dart';
import 'services/audio_service.dart';
import 'services/curriculum_service.dart';

final GetIt sl = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ProfileModelAdapter());
  Hive.registerAdapter(LevelProgressModelAdapter());

  // Open Hive boxes
  await Hive.openBox<ProfileModel>('profiles');
  await Hive.openBox<LevelProgressModel>('progress');
  await Hive.openBox('settings');

  // Setup service locator
  await _setupDependencies();

  runApp(const PhonicsJourneyApp());
}

Future<void> _setupDependencies() async {
  // Data sources
  sl.registerLazySingleton<HiveDatasource>(() => HiveDatasource());

  // Repositories
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(sl<HiveDatasource>()),
  );
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepository(sl<HiveDatasource>()),
  );

  // Services
  sl.registerLazySingleton<CurriculumService>(() => CurriculumService());
  sl.registerLazySingleton<AudioService>(() => AudioService());

  // Use cases
  sl.registerLazySingleton<GetCurriculum>(
    () => GetCurriculum(sl<CurriculumService>()),
  );
  sl.registerLazySingleton<ManageProfile>(
    () => ManageProfile(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<ManageProgress>(
    () => ManageProgress(sl<ProgressRepository>()),
  );

  // BLoCs
  sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(sl<ManageProfile>()),
  );
  sl.registerFactory<ProgressBloc>(
    () => ProgressBloc(sl<ManageProgress>()),
  );

  // Init curriculum
  await sl<CurriculumService>().loadCurriculum();
  // Init audio
  await sl<AudioService>().init();
}

class PhonicsJourneyApp extends StatelessWidget {
  const PhonicsJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Phonics Journey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.defaultTheme,
      routerConfig: AppRouter.router,
    );
  }
}
