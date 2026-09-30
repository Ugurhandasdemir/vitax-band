import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../../data/models.dart';
import '../add_food/add_food_screen.dart';
import 'barcode_result_screen.dart';
import 'photo_analysis_screen.dart';

enum ScanMode { barcode, photo }

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  ScanMode _mode = ScanMode.barcode;
  bool _flashOn = false;

  final List<({String name, String mealName, MealType meal, String time, int kcal, String macro, IconData icon})> _recentScans = [
    (
      name: 'Pınar Protein Süt 500ml',
      mealName: 'Kahvaltı',
      meal: MealType.breakfast,
      time: 'Bugün 08:30',
      kcal: 260,
      macro: '26g Protein',
      icon: Icons.local_drink,
    ),
    (
      name: 'Wasa Sade Çavdar Gevreği',
      mealName: 'Atıştırmalık',
      meal: MealType.snack,
      time: 'Dün 16:15',
      kcal: 105,
      macro: '4.2g Lif',
      icon: Icons.bakery_dining,
    ),
    (
      name: 'Züber Fıstık Ezmeli Bar',
      mealName: 'Atıştırmalık',
      meal: MealType.snack,
      time: '12 Nis',
      kcal: 182,
      macro: 'Şekersiz',
      icon: Icons.cookie,
    ),
  ];

  Future<void> _handleQuickAdd(int index) async {
    final item = _recentScans[index];
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    await ref.read(nutritionActionsProvider).addFood(
      FoodEntry(
        date: today,
        meal: item.meal,
        name: item.name,
        portion: '1 porsiyon',
        kcal: item.kcal,
        protein: item.name.contains('Protein') ? 26 : 3,
        carbs: item.name.contains('Wasa') ? 20 : 15,
        fat: item.name.contains('Züber') ? 8 : 2,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} günlüğe eklendi')),
    );
  }

  void _handleShutter() {
    if (_mode == ScanMode.barcode) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BarcodeResultScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PhotoAnalysisScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen-scan'),
      backgroundColor: VColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.xs),
          child: Column(
            children: [
              // Mode Toggle
              Center(
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: VColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _mode = ScanMode.barcode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _mode == ScanMode.barcode ? VColors.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(VRadius.pill),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Barkod',
                              style: VText.labelMd.copyWith(
                                color: _mode == ScanMode.barcode ? VColors.onPrimaryContainer : VColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _mode = ScanMode.photo),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _mode == ScanMode.photo ? VColors.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(VRadius.pill),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Fotoğraf',
                              style: VText.labelMd.copyWith(
                                color: _mode == ScanMode.photo ? VColors.onPrimaryContainer : VColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VSpace.sm),

              // Camera Viewfinder Box
              ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.card),
                child: Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: VColors.inverseSurface,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder Grid & Corner Targets
                      Center(
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            border: Border.all(color: VColors.primaryContainer.withOpacity(0.4), width: 1.5),
                            borderRadius: BorderRadius.circular(VRadius.md),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Laser scan line
                              Container(
                                height: 2,
                                width: double.infinity,
                                color: VColors.primaryContainer,
                              ),
                              // Instructions Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: VColors.inverseSurface.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(VRadius.pill),
                                ),
                                child: Text(
                                  'Barkodu veya yemeği çerçeveye alın',
                                  textAlign: TextAlign.center,
                                  style: VText.microTag.copyWith(color: VColors.inverseOnSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Live Active Detection Chip
                      Positioned(
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLowest.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(VRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: VColors.tertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Canlı Algılama Aktif', style: VText.microTag.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VSpace.sm),

              // Controls Bar: Flash, Shutter, Gallery, Search
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flash Button
                  IconButton(
                    key: const ValueKey('scan-flash-btn'),
                    style: IconButton.styleFrom(
                      backgroundColor: _flashOn ? VColors.primaryFixed : VColors.surfaceContainerHigh,
                      foregroundColor: _flashOn ? VColors.onPrimaryFixed : VColors.onSurface,
                      fixedSize: const Size(44, 44),
                    ),
                    icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, size: 20),
                    onPressed: () => setState(() => _flashOn = !_flashOn),
                  ),
                  const SizedBox(width: 20),
                  // Shutter Button
                  GestureDetector(
                    key: const ValueKey('scan-shutter-btn'),
                    onTap: _handleShutter,
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: VColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.center_focus_strong,
                          size: 26,
                          color: VColors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Gallery Button
                  IconButton(
                    key: const ValueKey('scan-gallery-btn'),
                    style: IconButton.styleFrom(
                      backgroundColor: VColors.surfaceContainerHigh,
                      foregroundColor: VColors.onSurface,
                      fixedSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.photo_library, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fotoğraf galerisi açılıyor')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Search text button
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AddFoodScreen()),
                  );
                },
                icon: const Icon(Icons.search, size: 18, color: VColors.primary),
                label: Text('Elle ara', style: VText.labelMd.copyWith(color: VColors.primary)),
              ),
              const SizedBox(height: VSpace.xs),

              // Recent Scans Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, size: 20, color: VColors.primary),
                      const SizedBox(width: 6),
                      Text('Son Kaydedilenler', style: VText.headlineMd),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('Tümünü Gör', style: VText.labelMd.copyWith(color: VColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              for (var i = 0; i < _recentScans.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: VCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VRadius.sm),
                          ),
                          child: Icon(_recentScans[i].icon, size: 22, color: VColors.secondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: VColors.secondaryFixed,
                                      borderRadius: BorderRadius.circular(VRadius.pill),
                                    ),
                                    child: Text(
                                      _recentScans[i].mealName,
                                      style: VText.microTag.copyWith(color: VColors.onSecondaryFixed),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _recentScans[i].time,
                                    style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _recentScans[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VText.bodyMdMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_recentScans[i].kcal} kcal • ${_recentScans[i].macro}',
                                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          key: const ValueKey('quick-add-btn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VColors.primaryContainer,
                            foregroundColor: VColors.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sm)),
                          ),
                          onPressed: () => _handleQuickAdd(i),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ekle'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
