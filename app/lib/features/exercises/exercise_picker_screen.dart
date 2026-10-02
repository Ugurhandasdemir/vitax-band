import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../data/exercise_catalog.dart';
import '../workout/workout_providers.dart';
import 'exercise_widgets.dart';

/// Egzersiz seçici: seçilen egzersizin id'sini geri döndürür.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  String _query = '';
  ExerciseGroup _group = ExerciseGroup.all;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exerciseCatalogProvider).value;
    final results =
        catalog?.search(query: _query, group: _group) ?? const <Exercise>[];
    return VDetailScaffold(
      key: const ValueKey('screen-exercise-picker'),
      title: 'Egzersiz Seç',
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(VSpace.margin),
            sliver: SliverList.list(
              children: [
                ExerciseSearchField(
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: VSpace.gutter),
                GroupChips(
                  selected: _group,
                  onChanged: (g) => setState(() => _group = g),
                ),
                const SizedBox(height: VSpace.gutter),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              VSpace.margin,
              0,
              VSpace.margin,
              VSpace.lg,
            ),
            sliver: SliverList.separated(
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: VSpace.sm),
              itemBuilder: (_, i) => ExerciseRow(
                exercise: results[i],
                trailing: const Icon(
                  PhosphorIconsRegular.plusCircle,
                  color: VColors.primary,
                ),
                onTap: () => Navigator.of(context).pop(results[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
