import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../../data/exercise_catalog.dart';
import '../workout/workout_providers.dart';

/// Kütüphane ve seçicide ortak egzersiz satırı: animasyonlu küçük resim + bilgiler.
class ExerciseRow extends ConsumerWidget {
  const ExerciseRow({
    super.key,
    required this.exercise,
    required this.onTap,
    this.trailing,
  });
  final Exercise exercise;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(exerciseMediaBuilderProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: VCard(
        padding: const EdgeInsets.all(VSpace.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.md),
              child: media(exercise.gifUrl, size: 72),
            ),
            const SizedBox(width: VSpace.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: Text(
                      exercise.bodyPartTr,
                      style: VText.microTag.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VText.bodyLgMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${exercise.equipmentTr} • ${exercise.targetTr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VText.bodyMd.copyWith(
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  PhosphorIconsRegular.caretRight,
                  color: VColors.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

/// Kas grubu çipleri (yatay kaydırılır). Seçili olan koyu.
class GroupChips extends StatelessWidget {
  const GroupChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final ExerciseGroup selected;
  final ValueChanged<ExerciseGroup> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: ExerciseGroup.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final g = ExerciseGroup.values[i];
        final on = g == selected;
        return GestureDetector(
          key: ValueKey('group-${g.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(g),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? VColors.onSurface : VColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(VRadius.pill),
              border: on
                  ? null
                  : Border.all(color: VColors.surfaceContainerHighest),
            ),
            child: Text(
              g.label,
              style: VText.labelMd.copyWith(
                color: on ? VColors.surface : VColors.onSurface,
              ),
            ),
          ),
        );
      },
    ),
  );
}

class ExerciseSearchField extends StatelessWidget {
  const ExerciseSearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: VColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(VRadius.pill),
      border: Border.all(color: VColors.surfaceContainerHighest),
    ),
    child: Row(
      children: [
        const Icon(PhosphorIconsRegular.magnifyingGlass, color: VColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            key: const ValueKey('exercise-search'),
            onChanged: onChanged,
            style: VText.bodyLg,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'Egzersiz veya kas ara...',
              hintStyle: VText.bodyMd.copyWith(color: VColors.outline),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Ekipman seçimi alt sayfası. Seçilen anahtarı (veya null=Tümü) döndürür.
Future<String?> pickEquipment(
  BuildContext context,
  ExerciseCatalog catalog,
  String? current,
) => showModalBottomSheet<String?>(
  context: context,
  backgroundColor: VColors.surface,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.cardLg)),
  ),
  builder: (ctx) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.7,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: VSpace.md),
          Center(child: Text('Ekipman', style: VText.headlineMd)),
          ListTile(
            title: const Text('Tümü'),
            trailing: current == null
                ? const Icon(PhosphorIconsRegular.check, color: VColors.primary)
                : null,
            onTap: () => Navigator.of(ctx).pop('__all__'),
          ),
          for (final e in catalog.equipmentList)
            ListTile(
              title: Text(equipmentLabelTr(e)),
              trailing: current == e
                  ? const Icon(PhosphorIconsRegular.check, color: VColors.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop(e),
            ),
        ],
      ),
    ),
  ),
);
