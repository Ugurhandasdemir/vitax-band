import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';

class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  int _periodIndex = 0; // 0: Hafta, 1: Ay

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen-health-insights'),
      backgroundColor: VColors.surface,
      appBar: AppBar(
        backgroundColor: VColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22, color: VColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Sağlık İçgörüleri', style: VText.headlineMd),
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
            // Period Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: VColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _periodIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _periodIndex == 0 ? VColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_view_week, size: 16, color: _periodIndex == 0 ? VColors.onPrimary : VColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              'Hafta',
                              style: VText.labelMd.copyWith(
                                color: _periodIndex == 0 ? VColors.onPrimary : VColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _periodIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _periodIndex == 1 ? VColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month, size: 16, color: _periodIndex == 1 ? VColors.onPrimary : VColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              'Ay',
                              style: VText.labelMd.copyWith(
                                color: _periodIndex == 1 ? VColors.onPrimary : VColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpace.md),

            // Overview Headline
            Row(
              children: [
                const Icon(Icons.auto_graph, size: 16, color: VColors.primary),
                const SizedBox(width: 4),
                Text(
                  _periodIndex == 0 ? 'HAFTALIK ANALİZ' : 'AYLIK ANALİZ',
                  style: VText.labelCaps.copyWith(color: VColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('Biyometrik Korelasyon Raporu', style: VText.headlineLg),
            const SizedBox(height: 4),
            Text(
              'Son 7 günün VitaxBand ve beslenme verileri hassasiyetle eşleştirildi.',
              style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
            ),
            const SizedBox(height: VSpace.md),

            // Micro Highlight Pill Strip
            Row(
              children: [
                Expanded(
                  child: VCard(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: VColors.secondaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(VRadius.sm),
                          ),
                          child: const Icon(Icons.sync, size: 18, color: VColors.secondary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SENKRONİZASYON', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('%100 Güvenilir', maxLines: 1, overflow: TextOverflow.ellipsis, style: VText.bodyMdMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VCard(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: VColors.tertiaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(VRadius.sm),
                          ),
                          child: const Icon(Icons.bolt, size: 18, color: VColors.tertiary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SKOR ETKİSİ', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('+14 Puan', style: VText.bodyMdMedium.copyWith(color: VColors.tertiary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpace.md),

            // Correlation Cards Stack
            // CARD 1: Sleep vs HR
            VCard(
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: VColors.secondaryContainer.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(VRadius.sm),
                              ),
                              child: const Icon(Icons.bedtime, size: 18, color: VColors.secondary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('BİLEŞİK ANALİZ', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  Text('Uyku Süresi & Ertesi Gün Nabız', maxLines: 1, overflow: TextOverflow.ellipsis, style: VText.headlineMd),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: VColors.secondaryFixed,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: Text('Yüksek Pozitif', style: VText.microTag.copyWith(color: VColors.secondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpace.sm),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('+45', style: VText.headlineLg.copyWith(color: VColors.secondary)),
                            const SizedBox(width: 4),
                            Text('dk derin uyku', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, size: 16, color: VColors.onSurfaceVariant),
                        Row(
                          children: [
                            Text('-4', style: VText.headlineLg.copyWith(color: VColors.tertiary)),
                            const SizedBox(width: 4),
                            Text('BPM (58 bpm)', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.sm),
                  // Chart Preview
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: CustomPaint(painter: _SleepHrCorrelationPainter()),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                      border: const Border(left: BorderSide(color: VColors.secondary, width: 4)),
                    ),
                    child: Text(
                      '7 saatin üzerinde uyuduğunuz günlerin ertesinde kalp toparlanmanız %22 daha hızlı gerçekleşiyor.',
                      style: VText.bodyMd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpace.md),

            // CARD 2: Steps vs Weight
            VCard(
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: VColors.tertiaryFixed,
                                borderRadius: BorderRadius.circular(VRadius.sm),
                              ),
                              child: const Icon(Icons.directions_walk, size: 18, color: VColors.tertiary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AKTİVİTE KORELASYONU', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  Text('Günlük Adım Sayısı & Kilo', maxLines: 1, overflow: TextOverflow.ellipsis, style: VText.headlineMd),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: VColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: Text('%35 İvme', style: VText.microTag.copyWith(color: VColors.tertiary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VRadius.sm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('KRİTİK EŞİK', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('8.500+ adım', style: VText.bodyMdMedium),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VRadius.sm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NET AÇIK', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('-320 kcal/gün', style: VText.bodyMdMedium.copyWith(color: VColors.tertiary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Haftalık Adım Hedefi Başarısı (5/7 Gün)', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                      Text('%71', style: VText.bodyMdMedium.copyWith(color: VColors.tertiary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VRadius.pill),
                    child: const LinearProgressIndicator(
                      value: 0.71,
                      minHeight: 8,
                      backgroundColor: VColors.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation(VColors.tertiary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                      border: const Border(left: BorderSide(color: VColors.tertiary, width: 4)),
                    ),
                    child: Text(
                      'VitaxBand verilerine göre adım hedefini yakaladığınız 5 gün, haftalık 320 kcal açık hedefinizi doğrudan karşıladı.',
                      style: VText.bodyMd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpace.md),

            // CARD 3: Calorie & Energy Balance
            VCard(
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
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: VColors.primaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_fire_department, size: 18, color: VColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('METABOLİK DENGE', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  Text('Kalori & Enerji Dengesi', maxLines: 1, overflow: TextOverflow.ellipsis, style: VText.headlineMd),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: VColors.primaryFixed,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: Text('Optimum', style: VText.microTag.copyWith(color: VColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpace.sm),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOPLAM KALORİ DEFİSİTİ', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                            Text('-2.240 kcal', style: VText.headlineLg.copyWith(color: VColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                child: LinearProgressIndicator(
                                  value: 0.82,
                                  minHeight: 8,
                                  backgroundColor: VColors.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(VColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('82% Hedef', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                      border: const Border(left: BorderSide(color: VColors.primary, width: 4)),
                    ),
                    child: Text(
                      'Protein oranı %30\'un üzerinde tutulduğunda kas kütlesi kaybı yaşanmadan yağ yakımı ve enerji kararlılığı sağlandı.',
                      style: VText.bodyMd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpace.md),

            // CARD 4: Recovery Trend HRV
            VCard(
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: VColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(VRadius.sm),
                              ),
                              child: const Icon(Icons.monitor_heart, size: 18, color: VColors.onSurfaceVariant),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('OTONOM SİNİR SİSTEMİ', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  Text('Toparlanma Trendi (HRV)', maxLines: 1, overflow: TextOverflow.ellipsis, style: VText.headlineMd),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: VColors.secondaryFixed,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: Text('Dengeli', style: VText.microTag.copyWith(color: VColors.secondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VRadius.sm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DİNLENİK HRV', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('62 ms', style: VText.headlineLg),
                              Text('▲ 3 ms stabil artış', style: VText.microTag.copyWith(color: VColors.tertiary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VRadius.sm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SİRKADİYEN RİTİM', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('%94 uyum', style: VText.headlineLg),
                              Text('Yüksek Düzenlilik', style: VText.microTag.copyWith(color: VColors.tertiary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                      border: const Border(left: BorderSide(color: VColors.secondary, width: 4)),
                    ),
                    child: Text(
                      'Dinlenik HRV 62 ms seviyesinde stabil kalırken, sirkadiyen ritim tutarlılığı %94 ile zihinsel berraklığınızı doğrudan destekliyor.',
                      style: VText.bodyMd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpace.md),

            // Export Actions
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VColors.primary,
                  foregroundColor: VColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.button)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF Raporu hazırlanıyor ve dışa aktarılıyor')),
                  );
                },
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Detaylı PDF Raporu Paylaş'),
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
                    const SnackBar(content: Text('Ham veriler (.CSV) indirildi')),
                  );
                },
                icon: const Icon(Icons.download, size: 18, color: VColors.onSurfaceVariant),
                label: Text('Ham Verileri İndir (.CSV)', style: VText.labelMd),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SleepHrCorrelationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = VColors.secondaryContainer;
    final linePaint = Paint()
      ..color = VColors.primaryContainer
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final days = 7;
    final w = size.width / days;
    for (var i = 0; i < days; i++) {
      final h = 15.0 + (i * 4) % 25;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * w + 8, size.height - h, w - 16, h),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }

    final path = Path();
    path.moveTo(w * 0.5, size.height * 0.3);
    for (var i = 1; i < days; i++) {
      path.lineTo(i * w + w * 0.5, size.height * 0.2 + (i % 3) * 5);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
