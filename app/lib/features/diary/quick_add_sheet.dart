import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/models.dart';

/// Öğün: verilmediyse saate göre seçer.
MealType defaultMealFor(DateTime now) {
  final h = now.hour;
  if (h < 10) return MealType.breakfast;
  if (h < 15) return MealType.lunch;
  if (h < 21) return MealType.dinner;
  return MealType.snack;
}

/// Sadece kalori ve öğünle tek dokunuşta kayıt.
Future<void> showQuickAddSheet(BuildContext context, {MealType? meal}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VRadius.cardLg),
        ),
      ),
      builder: (_) => _QuickAddSheet(initialMeal: meal),
    );

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet({this.initialMeal});
  final MealType? initialMeal;

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  final _kcal = TextEditingController();
  final _name = TextEditingController();
  late MealType _meal;
  String? _error;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal ?? defaultMealFor(ref.read(clockProvider)());
  }

  @override
  void dispose() {
    _kcal.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final kcal = int.tryParse(_kcal.text.trim());
    if (kcal == null || kcal <= 0) {
      setState(() => _error = 'Kalori gir');
      return;
    }
    final day = ref.read(selectedDayProvider);
    final name = _name.text.trim().isEmpty ? 'Hızlı kalori' : _name.text.trim();
    await ref
        .read(nutritionActionsProvider)
        .addFood(
          FoodEntry(
            date: day,
            meal: _meal,
            name: name,
            portion: '1 porsiyon',
            kcal: kcal,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      VSpace.margin,
      VSpace.md,
      VSpace.margin,
      MediaQuery.of(context).viewInsets.bottom + VSpace.md,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hızlı Kalori Ekle', style: VText.headlineMd),
        const SizedBox(height: VSpace.md),
        TextField(
          key: const ValueKey('quick-kcal'),
          controller: _kcal,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Kalori (kcal)',
            errorText: _error,
            filled: true,
            fillColor: VColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VRadius.button),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: VSpace.gutter),
        TextField(
          key: const ValueKey('quick-name'),
          controller: _name,
          decoration: InputDecoration(
            labelText: 'Ad (isteğe bağlı)',
            filled: true,
            fillColor: VColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VRadius.button),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: VSpace.gutter),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in MealType.values)
              GestureDetector(
                onTap: () => setState(() => _meal = m),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: m == _meal
                        ? VColors.primaryFixed
                        : VColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                    border: m == _meal
                        ? Border.all(color: VColors.primary)
                        : null,
                  ),
                  child: Text(
                    m.shortLabel,
                    style: VText.labelMd.copyWith(
                      color: m == _meal
                          ? VColors.primary
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: VSpace.md),
        SizedBox(
          width: double.infinity,
          height: VSpace.touchMin,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: VColors.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VRadius.button),
              ),
            ),
            onPressed: _submit,
            child: Text(
              'Ekle',
              style: VText.labelMd.copyWith(color: VColors.onPrimary),
            ),
          ),
        ),
      ],
    ),
  );
}
