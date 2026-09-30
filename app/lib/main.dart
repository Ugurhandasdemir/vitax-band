import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'app/providers.dart';
import 'data/band/ble_band_transport.dart';
import 'data/db/app_database.dart';
import 'data/repos/band_sample_repository.dart';
import 'data/repos/nutrition_repository.dart';
import 'data/repos/settings_repository.dart';
import 'data/repos/workout_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final db = AppDatabase(
    NativeDatabase(File(p.join(dir.path, 'vitax.sqlite'))),
  );
  runApp(
    ProviderScope(
      overrides: [
        bandTransportProvider.overrideWithValue(BleBandTransport()),
        nutritionRepositoryProvider.overrideWithValue(
          DriftNutritionRepository(db),
        ),
        bandSampleRepositoryProvider.overrideWithValue(
          DriftBandSampleRepository(db),
        ),
        settingsRepositoryProvider.overrideWithValue(
          DriftSettingsRepository(db),
        ),
        workoutRepositoryProvider.overrideWithValue(DriftWorkoutRepository(db)),
      ],
      child: const VitaxApp(),
    ),
  );
}
