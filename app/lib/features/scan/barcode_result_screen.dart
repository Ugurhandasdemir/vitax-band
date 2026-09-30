import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../../data/models.dart';

class BarcodeResultScreen extends ConsumerStatefulWidget {
  const BarcodeResultScreen({
    super.key,
    this.barcode = '8690504123456',
    this.productName = 'Kakaolu Protein Sütü',
    this.brand = 'Pınar Protein',
    this.category = 'Süt & Kahvaltılık',
    this.baseCal = 260,
    this.baseProtein = 26.0,
    this.baseCarb = 23.5,
    this.baseFat = 3.5,
  });

  final String barcode;
  final String productName;
  final String brand;
  final String category;
  final int baseCal;
  final double baseProtein;
  final double baseCarb;
  final double baseFat;

  @override
  ConsumerState<BarcodeResultScreen> createState() => _BarcodeResultScreenState();
}

class _BarcodeResultScreenState extends ConsumerState<BarcodeResultScreen> {
  int _quantity = 1;
  double _multiplier = 1.0;
  MealType _selectedMeal = MealType.breakfast;
  String _unitName = 'Kutu (500 ml)';

  static const _unitChips = [
    ('Kutu (500 ml)', 1.0),
    ('Porsiyon (250 ml)', 0.5),
    ('Gram (500g)', 1.0),
    ('100 ml', 0.2),
  ];

  static const _mealLabels = {
    MealType.breakfast: 'Kahvaltı',
    MealType.lunch: 'Öğle',
    MealType.dinner: 'Akşam',
    MealType.snack: 'Ara Öğün',
  };

  static const _mealIcons = {
    MealType.breakfast: Icons.wb_sunny_outlined,
    MealType.lunch: Icons.restaurant,
    MealType.dinner: Icons.nightlight_outlined,
    MealType.snack: Icons.local_cafe_outlined,
  };

  int get _currentCal => ((widget.baseCal * _quantity * _multiplier)).round();
  double get _currentProtein => widget.baseProtein * _quantity * _multiplier;
  double get _currentCarb => widget.baseCarb * _quantity * _multiplier;
  double get _currentFat => widget.baseFat * _quantity * _multiplier;

  Future<void> _handleAddToMeal() async {
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    await ref.read(nutritionActionsProvider).addFood(
      FoodEntry(
        date: today,
        meal: _selectedMeal,
        name: '${widget.brand} ${widget.productName}',
        portion: '$_quantity x $_unitName',
        kcal: _currentCal,
        protein: _currentProtein,
        carbs: _currentCarb,
        fat: _currentFat,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_mealLabels[_selectedMeal]} günlüğüne eklendi (${_currentCal} kcal)')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final mealLabel = _mealLabels[_selectedMeal]!;

    return Scaffold(
      key: const ValueKey('screen-barcode-result'),
      backgroundColor: VColors.surface,
      appBar: AppBar(
        backgroundColor: VColors.surface,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('barcode-back-btn'),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: VColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Barcode Result', style: VText.headlineMd),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: VColors.onSurfaceVariant),
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
                  // Verification Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.md, vertical: VSpace.sm),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 16, color: VColors.tertiary),
                            const SizedBox(width: 8),
                            Text(widget.barcode, style: VText.bodyMd),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: VColors.tertiaryFixed,
                            borderRadius: BorderRadius.circular(VRadius.pill),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: VColors.tertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('Doğrulandı', style: VText.microTag.copyWith(color: VColors.tertiary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Product Header Card
                  VCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(VRadius.md),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.local_drink, size: 40, color: VColors.secondary),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: VColors.surfaceContainerLowest.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('500 ml', style: VText.microTag),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: VSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.brand,
                                style: VText.labelCaps.copyWith(color: VColors.secondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: VText.headlineMd,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: VColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(VRadius.pill),
                                ),
                                child: Text(widget.category, style: VText.microTag),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('$_currentCal', style: VText.headlineLg.copyWith(color: VColors.primaryContainer)),
                                  const SizedBox(width: 4),
                                  Text('kcal', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                                  const SizedBox(width: 6),
                                  Text('• 1 Kutu Bazı', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Portion Selector Card
                  VCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('PORSİYON MİKTARI', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                            Text(_unitName, style: VText.bodyMdMedium.copyWith(color: VColors.secondary)),
                          ],
                        ),
                        const SizedBox(height: VSpace.sm),
                        // Stepper Controls
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VRadius.md),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                key: const ValueKey('portion-minus-btn'),
                                style: IconButton.styleFrom(
                                  backgroundColor: VColors.surfaceContainerLowest,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sm)),
                                ),
                                icon: const Icon(Icons.remove, size: 20),
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              ),
                              Column(
                                children: [
                                  Text('$_quantity', style: VText.headlineLg),
                                  Text('Adet', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                ],
                              ),
                              IconButton(
                                key: const ValueKey('portion-plus-btn'),
                                style: IconButton.styleFrom(
                                  backgroundColor: VColors.primaryContainer,
                                  foregroundColor: VColors.onPrimaryContainer,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sm)),
                                ),
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: _quantity < 10 ? () => setState(() => _quantity++) : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: VSpace.sm),
                        // Unit Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final (unit, mult) in _unitChips) ...[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(unit),
                                    selected: _unitName == unit,
                                    selectedColor: VColors.primaryContainer,
                                    labelStyle: VText.labelMd.copyWith(
                                      color: _unitName == unit ? VColors.onPrimaryContainer : VColors.onSurfaceVariant,
                                    ),
                                    backgroundColor: VColors.surfaceContainerLow,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.pill)),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() {
                                          _unitName = unit;
                                          _multiplier = mult;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Macro Split Card
                  VCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BESİN DEĞERLERİ', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('$_currentCal', style: VText.displayLg.copyWith(fontSize: 28)),
                                    const SizedBox(width: 4),
                                    Text('kcal', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: VColors.secondaryFixed,
                                    borderRadius: BorderRadius.circular(VRadius.pill),
                                  ),
                                  child: Text('%13 Günlük Hedef', style: VText.labelCaps.copyWith(color: VColors.onSecondaryFixed)),
                                ),
                                const SizedBox(height: 2),
                                Text('2.000 kcal referans', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: VSpace.md),
                        // Segmented bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(VRadius.pill),
                          child: SizedBox(
                            height: 8,
                            child: Row(
                              children: const [
                                Expanded(flex: 52, child: ColoredBox(color: VColors.secondary)),
                                Expanded(flex: 36, child: ColoredBox(color: VColors.tertiary)),
                                Expanded(flex: 12, child: ColoredBox(color: VColors.primaryContainer)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: VSpace.md),
                        // 3 Macro Tiles
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
                                    Text(_currentProtein.toStringAsFixed(1), style: VText.headlineMd),
                                    Text('gram (%52)', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
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
                                    Text(_currentCarb.toStringAsFixed(1), style: VText.headlineMd),
                                    Text('gram (%36)', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
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
                                    Text(_currentFat.toStringAsFixed(1), style: VText.headlineMd),
                                    Text('gram (%12)', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VSpace.md),
                        // Micro values row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VRadius.md),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('LİF', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text('${(0.5 * _quantity * _multiplier).toStringAsFixed(1)} g', style: VText.bodyMdMedium),
                                ],
                              ),
                              Container(width: 1, height: 24, color: VColors.surfaceContainerHigh),
                              Column(
                                children: [
                                  Text('KALSİYUM', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text('${(600 * _quantity * _multiplier).round()} mg', style: VText.bodyMdMedium),
                                ],
                              ),
                              Container(width: 1, height: 24, color: VColors.surfaceContainerHigh),
                              Column(
                                children: [
                                  Text('DOĞAL ŞEKER', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text('${(18 * _quantity * _multiplier).round()} g', style: VText.bodyMdMedium),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Meal Selection Card
                  VCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ÖĞÜN EŞLEŞMESİ', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                            Text('Günün Önerisi', style: VText.microTag.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Bu besin hangi öğününüze kaydedilsin?', style: VText.bodyMd),
                        const SizedBox(height: VSpace.sm),
                        Row(
                          children: [
                            for (final meal in MealType.values) ...[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedMeal = meal),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedMeal == meal ? VColors.primaryContainer : VColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(VRadius.md),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            _mealIcons[meal],
                                            size: 18,
                                            color: _selectedMeal == meal ? VColors.onPrimaryContainer : VColors.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _mealLabels[meal]!,
                                            style: VText.labelMd.copyWith(
                                              fontSize: 11,
                                              color: _selectedMeal == meal ? VColors.onPrimaryContainer : VColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Sticky Bottom CTA Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.sm),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  key: const ValueKey('barcode-add-btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VColors.primaryContainer,
                    foregroundColor: VColors.onPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.button)),
                  ),
                  onPressed: _handleAddToMeal,
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: Text(
                    '${mealLabel}ya Ekle ($_currentCal kcal)',
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
