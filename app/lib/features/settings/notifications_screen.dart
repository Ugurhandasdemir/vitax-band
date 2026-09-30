import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// Faz 5 — Bildirimler ve Uyarılar Ekranı
///
/// VitaxBand donanım titreşim uyarılarını (hareketsizlik, kritik nabız, düşük pil),
/// metabolik alışkanlık bildirimlerini (su, öğün, uyku) ve gece rahatsız etme modunu
/// yöneten ayarlar ekranı.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Donanım & Sağlık Uyarıları
  bool _sedentaryAlert = true;
  bool _highHrAlert = true;
  bool _lowBatteryAlert = true;

  // Alışkanlık & Takip Hatırlatıcıları
  bool _waterReminder = true;
  bool _breakfastReminder = true;
  bool _lunchReminder = true;
  bool _dinnerReminder = true;
  bool _windDownReminder = true;

  // Rahatsız Etme Modu
  bool _sleepDnd = true;

  // Kayıt Durumu
  bool _isSaved = false;
  Timer? _savedTimer;

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  void _handleSave() {
    setState(() {
      _isSaved = true;
    });

    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isSaved = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirim tercihleri VitaxBand bilekliğe ve cihaza kaydedildi.'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen-notifications'),
      backgroundColor: VColors.surface,
      appBar: AppBar(
        backgroundColor: VColors.surface,
        elevation: 0,
        title: Text('Bildirimler ve Uyarılar', style: VText.headlineMd),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: VSpace.margin,
              right: VSpace.margin,
              top: VSpace.xs,
              bottom: 90, // Alt kaydet butonu için boşluk
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Giriş Bannerı
                _buildIntroBanner(),
                const SizedBox(height: VSpace.md),

                // BÖLÜM 1: Donanım & Sağlık Uyarıları
                _buildHardwareAlertsSection(),
                const SizedBox(height: VSpace.md),

                // BÖLÜM 2: Alışkanlık & Takip Hatırlatıcıları
                _buildHabitRemindersSection(),
                const SizedBox(height: VSpace.md),

                // BÖLÜM 3: Rahatsız Etme Modu
                _buildDndSection(),
                const SizedBox(height: VSpace.md),
              ],
            ),
          ),

          // Sticky Bottom Save Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(VSpace.margin),
              decoration: BoxDecoration(
                color: VColors.surface.withAlpha(240),
                border: Border(top: BorderSide(color: VColors.outlineVariant.withAlpha(50))),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const ValueKey('notifications-save-btn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved ? VColors.tertiary : VColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sm)),
                    ),
                    icon: Icon(_isSaved ? Icons.check_circle : Icons.save, size: 20),
                    label: Text(
                      _isSaved ? 'Kaydedildi!' : 'Tercihleri Kaydet',
                      style: VText.labelMd.copyWith(color: Colors.white),
                    ),
                    onPressed: _handleSave,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      padding: const EdgeInsets.all(VSpace.margin),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: const Border(left: BorderSide(color: VColors.primary, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: VColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vibration, color: VColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'VitaxBand titreşim uyarıları ve uygulama bildirim tercihlerinizi yönetin.',
              style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.watch, color: VColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Donanım & Sağlık Uyarıları',
                  style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: VColors.tertiaryFixed,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: VColors.tertiary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text('Bağlı', style: VText.labelCaps.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpace.xs),

        // 1. Hareketsizlik Uyarısı
        Container(
          padding: const EdgeInsets.all(VSpace.margin),
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: const Icon(Icons.accessibility_new, color: VColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hareketsizlik Uyarısı', style: VText.labelMd),
                        const SizedBox(height: 2),
                        Text(
                          '50 dakika kesintisiz hareketsizlikte hafif bileklik titreşimi',
                          style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sedentaryAlert,
                    activeColor: VColors.primary,
                    onChanged: (v) => setState(() => _sedentaryAlert = v),
                  ),
                ],
              ),
              if (_sedentaryAlert) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: VColors.outlineVariant.withAlpha(40)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: VColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('Zaman Aralığı', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('09:00 - 19:00', style: VText.labelCaps.copyWith(color: VColors.onSurface)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. Yüksek Dinlenik Nabız
        Container(
          padding: const EdgeInsets.all(VSpace.margin),
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: VColors.errorContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: const Icon(Icons.favorite, color: VColors.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Yüksek Dinlenik Nabız',
                                style: VText.labelMd,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: VColors.errorContainer,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text('Kritik', style: VText.labelCaps.copyWith(color: VColors.onErrorContainer)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dinlenme anında 10 dk boyunca >100 BPM nabız algılandığında uyar',
                          style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _highHrAlert,
                    activeColor: VColors.primary,
                    onChanged: (v) => setState(() => _highHrAlert = v),
                  ),
                ],
              ),
              if (_highHrAlert) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: VColors.outlineVariant.withAlpha(40)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tetiklenme Eşiği', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VColors.errorContainer.withAlpha(60),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('100 BPM', style: VText.labelCaps.copyWith(color: VColors.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3. Düşük Pil Uyarısı
        Container(
          padding: const EdgeInsets.all(VSpace.margin),
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: VColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(VRadius.sm),
                ),
                child: const Icon(Icons.battery_alert, color: VColors.outline, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Düşük Pil Uyarısı', style: VText.labelMd),
                    const SizedBox(height: 2),
                    Text(
                      'Kalan şarj < %15 olduğunda bildirim gönder',
                      style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _lowBatteryAlert,
                activeColor: VColors.primary,
                onChanged: (v) => setState(() => _lowBatteryAlert = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fact_check, color: VColors.secondary, size: 18),
            const SizedBox(width: 6),
            Text(
              'Alışkanlık & Takip Hatırlatıcıları',
              style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: VSpace.xs),

        // 1. Su Tüketim Hatırlatıcısı
        Container(
          padding: const EdgeInsets.all(VSpace.margin),
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: VColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: const Icon(Icons.water_drop, color: VColors.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Su Tüketim Hatırlatıcısı', style: VText.labelMd),
                        const SizedBox(height: 2),
                        Text(
                          'Metabolik hidrasyon ritminizi canlı tutun',
                          style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _waterReminder,
                    activeColor: VColors.secondary,
                    onChanged: (v) => setState(() => _waterReminder = v),
                  ),
                ],
              ),
              if (_waterReminder) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: VColors.outlineVariant.withAlpha(40)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('2 SAATTE BİR', style: VText.labelCaps.copyWith(color: VColors.secondary, fontWeight: FontWeight.bold)),
                    ),
                    Text('08:30 – 21:30', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. Öğün Girişi Bildirimi
        Container(
          padding: const EdgeInsets.all(VSpace.margin),
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: const Icon(Icons.restaurant, color: VColors.tertiary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Öğün Girişi Bildirimi', style: VText.labelMd),
                        const SizedBox(height: 2),
                        Text(
                          'Makro ve kalori loglarını unutmamak için zamanlanmış bildirimler',
                          style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMealChip('Kahvaltı 09:00', Icons.breakfast_dining, _breakfastReminder, (v) => setState(() => _breakfastReminder = v)),
                    const SizedBox(width: 6),
                    _buildMealChip('Öğle 13:00', Icons.lunch_dining, _lunchReminder, (v) => setState(() => _lunchReminder = v)),
                    const SizedBox(width: 6),
                    _buildMealChip('Akşam 19:30', Icons.dinner_dining, _dinnerReminder, (v) => setState(() => _dinnerReminder = v)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3. Akıllı Uyku Vakti (Wind-down)
        Container(
          padding: const EdgeInsets.all(VSpace.margin),
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: VColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: const Icon(Icons.bedtime, color: VColors.tertiary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Akıllı Uyku Vakti (Wind-down)', style: VText.labelMd),
                        const SizedBox(height: 2),
                        Text(
                          '7.5 saat uyku hedefiniz için ekrandan uzaklaşma ve dinlenme anı',
                          style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _windDownReminder,
                    activeColor: VColors.tertiary,
                    onChanged: (v) => setState(() => _windDownReminder = v),
                  ),
                ],
              ),
              if (_windDownReminder) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: VColors.outlineVariant.withAlpha(40)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hatırlatma Saati', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('23:00', style: VText.labelCaps.copyWith(color: VColors.onSurface, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealChip(String label, IconData icon, bool active, ValueChanged<bool> onChanged) {
    return FilterChip(
      selected: active,
      label: Text(label),
      avatar: Icon(icon, size: 16, color: active ? VColors.primary : VColors.onSurfaceVariant),
      selectedColor: VColors.primaryFixed,
      checkmarkColor: VColors.primary,
      labelStyle: VText.labelCaps.copyWith(color: active ? VColors.primary : VColors.onSurface),
      onSelected: onChanged,
    );
  }

  Widget _buildDndSection() {
    return Container(
      padding: const EdgeInsets.all(VSpace.margin),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(VRadius.sm),
            ),
            child: const Icon(Icons.do_not_disturb_on, color: VColors.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gece Uykusu Algılama', style: VText.labelMd),
                const SizedBox(height: 2),
                Text(
                  'Gece uykusu sensörlerce algılandığında tüm titreşim ve uyarıları otomatik sessize al.',
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _sleepDnd,
            activeColor: VColors.primary,
            onChanged: (v) => setState(() => _sleepDnd = v),
          ),
        ],
      ),
    );
  }
}
