import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../../data/models.dart';

class PhotoAnalysisScreen extends ConsumerStatefulWidget {
  const PhotoAnalysisScreen({super.key});

  @override
  ConsumerState<PhotoAnalysisScreen> createState() => _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends ConsumerState<PhotoAnalysisScreen> {
  MealType _selectedMeal = MealType.lunch;

  static const _mealLabels = {
    MealType.breakfast: 'Kahvaltı',
    MealType.lunch: 'Öğle Yemeği',
    MealType.dinner: 'Akşam',
    MealType.snack: 'Ara Öğün',
  };

  final List<({String name, String portion, int kcal, String confidence, Color badgeColor, IconData icon})> _detectedFoods = [
    (
      name: 'Izgara Tavuk Göğsü',
      portion: '180 g',
      kcal: 295,
      confidence: '%98 GÜVEN',
      badgeColor: VColors.tertiaryFixed,
      icon: PhosphorIconsRegular.forkKnife,
    ),
    (
      name: 'Haşlanmış Kinoa & Nar',
      portion: '1 kase (120 g)',
      kcal: 165,
      confidence: '%94 GÜVEN',
      badgeColor: VColors.tertiaryFixed,
      icon: PhosphorIconsFill.leaf,
    ),
    (
      name: 'Dilim Avokado',
      portion: '40 g (1/4 adet)',
      kcal: 64,
      confidence: '%89 ORTA',
      badgeColor: VColors.secondaryFixed,
      icon: PhosphorIconsFill.leaf,
    ),
  ];

  Future<void> _handleConfirm() async {
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final actions = ref.read(nutritionActionsProvider);

    for (final item in _detectedFoods) {
      await actions.addFood(
        FoodEntry(
          date: today,
          meal: _selectedMeal,
          name: item.name,
          portion: item.portion,
          kcal: item.kcal,
          protein: item.name.contains('Tavuk') ? 40 : 4,
          carbs: item.name.contains('Kinoa') ? 28 : 2,
          fat: item.name.contains('Avokado') ? 10 : 3,
        ),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_mealLabels[_selectedMeal]} günlüğüne 3 besin eklendi (524 kcal)')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final mealLabel = _mealLabels[_selectedMeal]!;

    return Scaffold(
      key: const ValueKey('screen-photo-analysis'),
      backgroundColor: VColors.surface,
      appBar: AppBar(
        backgroundColor: VColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, size: 20, color: VColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Photo Estimate Result', style: VText.headlineMd),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: VColors.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Preview with Vision AI Overlays
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VRadius.card),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: VColors.inverseSurface,
                      ),
                      child: Stack(
                        children: [
                          // Background pattern simulation
                          Center(
                            child: Icon(PhosphorIconsRegular.bowlFood, size: 96, color: Colors.white.withOpacity(0.08)),
                          ),
                          // AI Engine Badge
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: VColors.inverseSurface.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(VRadius.pill),
                              ),
                              child: Row(
                                children: [
                                  const Icon(PhosphorIconsBold.sparkle, size: 14, color: VColors.tertiaryFixed),
                                  const SizedBox(width: 6),
                                  Text(
                                    'AI Besin Tanıma • VitaxVision AI',
                                    style: VText.labelCaps.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Tag Marker 1: Grilled Chicken
                          Positioned(
                            top: 70,
                            left: 90,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: VColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: VColors.inverseSurface.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(VRadius.pill),
                                  ),
                                  child: Text('Izgara Tavuk', style: VText.microTag.copyWith(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          // Tag Marker 2: Quinoa Salad
                          Positioned(
                            bottom: 60,
                            right: 40,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: VColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: VColors.inverseSurface.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(VRadius.pill),
                                  ),
                                  child: Text('Kinoa Salatası', style: VText.microTag.copyWith(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          // Tag Marker 3: Avocado
                          Positioned(
                            bottom: 30,
                            left: 50,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: VColors.tertiary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: VColors.inverseSurface.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(VRadius.pill),
                                  ),
                                  child: Text('Avokado', style: VText.microTag.copyWith(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          // Retake Button
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: VColors.surfaceContainerLowest.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsRegular.camera, size: 18, color: VColors.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Meal Timing Selector Pills
                  Text('ÖĞÜN ZAMANI SEÇİMİ', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final meal in MealType.values) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_mealLabels[meal]!),
                              selected: _selectedMeal == meal,
                              selectedColor: VColors.primary,
                              labelStyle: VText.labelMd.copyWith(
                                color: _selectedMeal == meal ? VColors.onPrimary : VColors.onSurfaceVariant,
                              ),
                              backgroundColor: VColors.surfaceContainerLow,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.pill)),
                              onSelected: (val) {
                                if (val) setState(() => _selectedMeal = meal);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Total Nutrition Summary Bento Card
                  VCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TAHMİNİ ENERJİ', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('524', style: VText.displayLg.copyWith(fontSize: 28)),
                                    const SizedBox(width: 4),
                                    Text('kcal', style: VText.headlineMd.copyWith(color: VColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: VColors.tertiaryFixed.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(VRadius.pill),
                              ),
                              child: Row(
                                children: [
                                  const Icon(PhosphorIconsFill.sealCheck, size: 16, color: VColors.tertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Optimum Denge',
                                    style: VText.labelCaps.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VSpace.md),
                        // 3 Macro Split Grid
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: VColors.secondaryFixed.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(VRadius.md),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('PROTEİN', style: VText.labelCaps.copyWith(color: VColors.secondary)),
                                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: VColors.secondary, shape: BoxShape.circle)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('48', style: VText.headlineMd),
                                        Text('g', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                      ],
                                    ),
                                    Text('%37 Oran', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: VColors.tertiaryFixed.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(VRadius.md),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('KARB', style: VText.labelCaps.copyWith(color: VColors.tertiary)),
                                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: VColors.tertiary, shape: BoxShape.circle)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('32', style: VText.headlineMd),
                                        Text('g', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                      ],
                                    ),
                                    Text('%25 Oran', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: VColors.primaryFixed.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(VRadius.md),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('YAĞ', style: VText.labelCaps.copyWith(color: VColors.primaryContainer)),
                                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: VColors.primaryContainer, shape: BoxShape.circle)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('16', style: VText.headlineMd),
                                        Text('g', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                      ],
                                    ),
                                    Text('%38 Oran', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Detected Foods Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Tespit Edilen Yiyecekler (3 Kalem)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.headlineMd,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('Tümünü Düzenle', style: VText.labelMd.copyWith(color: VColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final item in _detectedFoods) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: VCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: VColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(VRadius.sm),
                              ),
                              child: Icon(item.icon, size: 20, color: VColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: VText.bodyLgMedium),
                                  const SizedBox(height: 2),
                                  Text(item.portion, style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${item.kcal} kcal', style: VText.bodyMdMedium),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.badgeColor,
                                    borderRadius: BorderRadius.circular(VRadius.pill),
                                  ),
                                  child: Text(
                                    item.confidence,
                                    style: VText.microTag.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: VSpace.sm),

                  // Correction Row
                  Container(
                    padding: const EdgeInsets.all(VSpace.md),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: VColors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(PhosphorIconsRegular.question, size: 20, color: VColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Yanlış veya eksik bir şey mi var?', style: VText.bodyMd),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Elle Düzelt veya Besin Ekle',
                                  style: VText.labelMd.copyWith(color: VColors.primary, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Sticky Bottom Confirmation CTA
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.sm),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  key: const ValueKey('photo-confirm-btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VColors.primaryContainer,
                    foregroundColor: VColors.onPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.button)),
                  ),
                  onPressed: _handleConfirm,
                  icon: const Icon(PhosphorIconsRegular.checks, size: 20),
                  label: Text(
                    'Onayla ve ${mealLabel}ne Ekle (524 kcal)',
                    style: VText.labelMd.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
