import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';

class WeeklyPlanScreen extends StatelessWidget {
  const WeeklyPlanScreen({super.key});

  static const _days = [
    (
      day: 'Pzt',
      name: 'Göğüs & Triceps',
      tag: 'Bugün Aktif',
      tagActive: true,
      time: 'Kuvvet • 45 dk',
      cal: '2.100 kcal',
      protein: '150g P',
      isRest: false,
    ),
    (
      day: 'Sal',
      name: 'Bacak & Karın',
      tag: 'Antrenman',
      tagActive: false,
      time: 'Hipertrofi • 50 dk',
      cal: '2.150 kcal',
      protein: '150g P',
      isRest: false,
    ),
    (
      day: 'Çar',
      name: 'Dinlenme & Aktif Toparlanma',
      tag: 'Toparlanma',
      tagActive: false,
      time: 'Hafif Yürüyüş',
      cal: '1.900 kcal',
      protein: '140g P',
      isRest: true,
    ),
    (
      day: 'Per',
      name: 'Sırt & Biceps',
      tag: 'Antrenman',
      tagActive: false,
      time: 'Kuvvet • 45 dk',
      cal: '2.100 kcal',
      protein: '150g P',
      isRest: false,
    ),
    (
      day: 'Cum',
      name: 'Omuz & Kol',
      tag: 'Antrenman',
      tagActive: false,
      time: 'Hipertrofi • 40 dk',
      cal: '2.050 kcal',
      protein: '150g P',
      isRest: false,
    ),
    (
      day: 'Cmt',
      name: 'HIIT Kardiyo & Esneklik',
      tag: 'Kondisyon',
      tagActive: false,
      time: 'Yoğun • 30 dk',
      cal: '2.200 kcal',
      protein: '145g P',
      isRest: false,
    ),
    (
      day: 'Paz',
      name: 'Tam Dinlenme & Kas Yenilenmesi',
      tag: 'Yenilenme',
      tagActive: false,
      time: 'Pasif Dinlenme',
      cal: '1.850 kcal',
      protein: '135g P',
      isRest: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen-weekly-plan'),
      backgroundColor: VColors.surface,
      appBar: AppBar(
        backgroundColor: VColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22, color: VColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Haftalık Ai Planı', style: VText.headlineMd),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: VColors.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Badge & Sync Status
            VCard(
              color: VColors.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: VColors.primaryFixed,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 14, color: VColors.onPrimaryFixed),
                            const SizedBox(width: 4),
                            Text(
                              'AI Döngüsü v4.2',
                              style: VText.microTag.copyWith(color: VColors.onPrimaryFixed),
                            ),
                          ],
                        ),
                      ),
                      Row(
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
                          Text('VitaxBand Kalibrasyonlu', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'YAPAY ZEKA ANTRENMAN & BESLENME DÖNGÜSÜ',
                    style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bu Haftanın Programı', style: VText.headlineMd),
                      Text('7 Günlük Akış', style: VText.labelMd.copyWith(color: VColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpace.md),

            // Quick Targets Stat Row
            Row(
              children: [
                Expanded(
                  child: VCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: VColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_fire_department, size: 16, color: VColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text('Kalori Ort.', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('2.050', style: VText.headlineMd),
                        Text('kcal / gün', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: VColors.secondaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.egg_alt, size: 16, color: VColors.secondary),
                        ),
                        const SizedBox(height: 4),
                        Text('Protein', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('148g', style: VText.headlineMd),
                        Text('145-150g', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: VColors.secondaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop, size: 16, color: VColors.secondary),
                        ),
                        const SizedBox(height: 4),
                        Text('Hidrasyon', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('2.5 L', style: VText.headlineMd),
                        Text('günlük hedef', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpace.md),

            // 7-Day Interactive Calendar Flow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('HAFTALIK GÜN DAĞILIMI', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                Row(
                  children: [
                    const Icon(Icons.tune, size: 12, color: VColors.tertiary),
                    const SizedBox(width: 4),
                    Text('HRV Uyarlanabilir', style: VText.microTag.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            for (final day in _days) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: day.isRest ? VColors.surfaceContainerLow : VColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(VRadius.md),
                    border: Border.all(color: VColors.surfaceContainerHighest),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(VRadius.md),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          if (day.tagActive)
                            Container(width: 4, color: VColors.primary),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: day.tagActive
                                                    ? VColors.primaryFixed
                                                    : (day.isRest ? VColors.tertiaryFixed : VColors.surfaceContainer),
                                                borderRadius: BorderRadius.circular(VRadius.sm),
                                              ),
                                              child: Text(
                                                day.day,
                                                style: VText.labelMd.copyWith(
                                                  color: day.tagActive
                                                      ? VColors.primary
                                                      : (day.isRest ? VColors.tertiary : VColors.onSurface),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                day.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: VText.bodyMdMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: day.tagActive
                                              ? VColors.primary
                                              : (day.isRest ? VColors.tertiaryFixed : VColors.secondaryFixed),
                                          borderRadius: BorderRadius.circular(VRadius.pill),
                                        ),
                                        child: Text(
                                          day.tag,
                                          style: VText.microTag.copyWith(
                                            color: day.tagActive
                                                ? VColors.onPrimary
                                                : (day.isRest ? VColors.onTertiaryFixed : VColors.onSecondaryFixed),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 14, color: VColors.primary),
                                        const SizedBox(width: 4),
                                        Text(day.time, style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.local_fire_department, size: 14, color: VColors.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text(day.cal, style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.restaurant, size: 14, color: VColors.secondary),
                                        const SizedBox(width: 4),
                                        Text(day.protein, style: VText.bodyMd.copyWith(color: VColors.secondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: VSpace.md),

            // AI Grounding & Rationale Module
            VCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: VColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: VColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Dr. Selin Demir', style: VText.labelMd),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 14, color: VColors.primary),
                            ],
                          ),
                          Text('Vitax AI Biyometrik Koçu', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpace.md),
                  Text('Bu Plan Neden Oluşturuldu?', style: VText.labelMd),
                  const SizedBox(height: 8),
                  _RationaleTile(
                    icon: Icons.bedtime,
                    iconColor: VColors.secondary,
                    text: 'Geçen haftaki VitaxBand ortalama uyku süreniz 7s 18dk ve toparlanma skorunuz %88 ölçüldü.',
                  ),
                  const SizedBox(height: 6),
                  _RationaleTile(
                    icon: Icons.favorite,
                    iconColor: VColors.primary,
                    text: "Dinlenik nabzınız 63'ten 58 BPM'e gerileyerek kardiyovasküler verimliliğinizin arttığını kanıtladı.",
                  ),
                  const SizedBox(height: 6),
                  _RationaleTile(
                    icon: Icons.flash_auto,
                    iconColor: VColors.tertiary,
                    text: 'Çarşamba ve Pazar günlerine yerleştirilen toparlanma blokları, overtraining riskini önlemek için HRV dengenize göre uyarlandı.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpace.md),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VColors.primaryContainer,
                  foregroundColor: VColors.onPrimaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.button)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Haftalık AI planı kabul edildi ve takvime işlendi')),
                  );
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Planı Kabul Et ve Takvime Ekle'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.button)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yeniden oluşturma parametreleri hazırlanıyor')),
                  );
                },
                icon: const Icon(Icons.tune, size: 18, color: VColors.onSurfaceVariant),
                label: Text('Yeniden Oluştur (Parametreleri Değiştir)', style: VText.labelMd),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RationaleTile extends StatelessWidget {
  const _RationaleTile({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant))),
        ],
      ),
    );
  }
}
