import 'package:drift/native.dart';
import 'package:vitax_app/data/db/app_database.dart';
import 'package:vitax_app/data/repos/band_sample_repository.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';
import 'package:vitax_app/data/repos/workout_repository.dart';

import 'band_sample_contract.dart';
import 'nutrition_contract.dart';
import 'settings_contract.dart';
import 'workout_contract.dart';

AppDatabase memDb() => AppDatabase(NativeDatabase.memory());

void main() {
  nutritionContract('bellek', () async => InMemoryNutritionRepository());
  nutritionContract('sqlite', () async => DriftNutritionRepository(memDb()));
  workoutContract('bellek', () async => InMemoryWorkoutRepository());
  workoutContract('sqlite', () async => DriftWorkoutRepository(memDb()));
  settingsContract('bellek', () async => InMemorySettingsRepository());
  settingsContract('sqlite', () async => DriftSettingsRepository(memDb()));
  bandSampleContract('bellek', () async => InMemoryBandSampleRepository());
  bandSampleContract('sqlite', () async => DriftBandSampleRepository(memDb()));
}
