import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// Faz 5 — Veri Kasası ve Gizlilik Ekranı
///
/// Kullanıcının tüm biyometrik verilerinin telefonunda AES-256 ile şifreli tutulduğunu,
/// Apple Health veya üçüncü taraf buluta veri aktarılmadığını gösteren,
/// kategori bazlı depolama kullanımını ve AI Koç izinlerini yöneten ekran.
class DataVaultScreen extends StatefulWidget {
  const DataVaultScreen({super.key});

  @override
  State<DataVaultScreen> createState() => _DataVaultScreenState();
}

class _DataVaultScreenState extends State<DataVaultScreen> {
  bool _allowHeart = true;
  bool _allowSleep = true;
  bool _allowWorkout = true;
  bool _allowMeal = true;
  bool _allowWeight = true;

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: VColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: VColors.error, size: 24),
              const SizedBox(width: 8),
              Text('Emin misiniz?', style: VText.headlineMd),
            ],
          ),
          content: Text(
            'Tüm sağlık geçmişiniz ve AI öğrenim modelleri cihazınızdan tamamen yok edilecektir.',
            style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Vazgeç', style: VText.labelMd.copyWith(color: VColors.onSurface)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: VColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sm)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tüm şifreli yerel veriler güvenli bir şekilde silindi.'),
                    backgroundColor: VColors.error,
                  ),
                );
              },
              child: const Text('Evet, Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen-data-vault'),
      backgroundColor: VColors.surface,
      appBar: AppBar(
        backgroundColor: VColors.surface,
        elevation: 0,
        title: Text('Veri Kasası ve Gizlilik', style: VText.headlineMd),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Şifreli Bellek Özeti Kartı
            _buildEncryptedStorageCard(),
            const SizedBox(height: VSpace.md),

            // 2. Saklanan Biyometrik Veriler (6 Kategori)
            _buildBiometricCategoriesSection(),
            const SizedBox(height: VSpace.md),

            // 3. AI Koç Veri İzinleri
            _buildAiPermissionsSection(),
            const SizedBox(height: VSpace.md),

            // 4. Senkronizasyon ve Dışa Aktar
            _buildSyncAndExportSection(),
            const SizedBox(height: VSpace.md),

            // 5. Riskli Alan (Tehlikeli Bölge)
            _buildDangerZoneSection(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptedStorageCard() {
    return Container(
      padding: const EdgeInsets.all(VSpace.margin),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: VColors.outlineVariant.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 14, color: VColors.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Cihaz İçi Şifreli Bellek',
                      style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: VColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AES-256',
                  style: VText.labelCaps.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('42.8', style: VText.displayLg.copyWith(color: VColors.onSurface)),
                  const SizedBox(width: 4),
                  Text('MB', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                ],
              ),
              Text(
                '500 MB AYRILAN ALAN',
                style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 6 Parçalı Segment Göstergesi
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.pill),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(flex: 42, child: Container(color: VColors.primary)),
                  const SizedBox(width: 1),
                  Expanded(flex: 15, child: Container(color: VColors.secondary)),
                  const SizedBox(width: 1),
                  Expanded(flex: 10, child: Container(color: VColors.secondaryFixed)),
                  const SizedBox(width: 1),
                  Expanded(flex: 13, child: Container(color: VColors.tertiary)),
                  const SizedBox(width: 1),
                  Expanded(flex: 16, child: Container(color: VColors.primaryFixed)),
                  const SizedBox(width: 1),
                  Expanded(flex: 4, child: Container(color: VColors.outline)),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpace.sm),
          Container(
            padding: const EdgeInsets.all(VSpace.sm),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user, size: 18, color: VColors.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verileriniz doğrudan telefonunuzda AES-256 ile şifrelenir. Apple Health veya üçüncü taraf bulut sunucularına asla aktarılmaz.',
                    style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saklanan Biyometrik Veriler', style: VText.headlineMd),
            Text('6 KATEGORİ', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: VSpace.xs),
        Container(
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Column(
            children: [
              _buildCategoryTile(
                icon: Icons.favorite,
                iconColor: VColors.primary,
                title: 'Canlı Nabız Akışı',
                subtitle: 'VitaxBand PPG • 1.4M veri noktası',
                sizeText: '18.2 MB',
              ),
              _buildDivider(),
              _buildCategoryTile(
                icon: Icons.directions_walk,
                iconColor: VColors.secondary,
                title: 'Adım & Hareket Verileri',
                subtitle: 'İvmeölçer logları ve kadans',
                sizeText: '6.4 MB',
              ),
              _buildDivider(),
              _buildCategoryTile(
                icon: Icons.bedtime,
                iconColor: VColors.secondary,
                title: 'Uyku Evreleri ve Hipnogram',
                subtitle: '30 günlük derin/REM ham veri',
                sizeText: '4.1 MB',
              ),
              _buildDivider(),
              _buildCategoryTile(
                icon: Icons.fitness_center,
                iconColor: VColors.tertiary,
                title: 'Antrenman ve Efor Kayıtları',
                subtitle: 'Set/tekrar ve nabız haritası',
                sizeText: '5.8 MB',
              ),
              _buildDivider(),
              _buildCategoryTile(
                icon: Icons.restaurant,
                iconColor: VColors.primary,
                title: 'Beslenme ve Öğün Günlüğü',
                subtitle: 'Fotoğraf analizleri ve kaloriler',
                sizeText: '7.1 MB',
              ),
              _buildDivider(),
              _buildCategoryTile(
                icon: Icons.straighten,
                iconColor: VColors.onSurfaceVariant,
                title: 'Kilo ve Beden Ölçüleri',
                subtitle: 'Manuel ölçüm geçmişi',
                sizeText: '1.2 MB',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String sizeText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: VColors.surfaceContainer,
              borderRadius: BorderRadius.circular(VRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: VText.labelMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(sizeText, style: VText.labelCaps.copyWith(color: VColors.onSurface)),
                  ],
                ),
                Text(
                  subtitle,
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Koç Veri İzinleri', style: VText.headlineMd),
        const SizedBox(height: 2),
        Text(
          "AI Koç'un erişebileceği yerel analiz katmanları:",
          style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: VSpace.xs),
        Container(
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Column(
            children: [
              _buildPermissionSwitch(
                icon: Icons.monitor_heart,
                iconColor: VColors.primary,
                title: 'Nabız ve Biyometri',
                value: _allowHeart,
                onChanged: (v) => setState(() => _allowHeart = v),
              ),
              _buildDivider(),
              _buildPermissionSwitch(
                icon: Icons.bedtime,
                iconColor: VColors.secondary,
                title: 'Uyku ve Toparlanma',
                value: _allowSleep,
                onChanged: (v) => setState(() => _allowSleep = v),
              ),
              _buildDivider(),
              _buildPermissionSwitch(
                icon: Icons.fitness_center,
                iconColor: VColors.tertiary,
                title: 'Antrenman Günlükleri',
                value: _allowWorkout,
                onChanged: (v) => setState(() => _allowWorkout = v),
              ),
              _buildDivider(),
              _buildPermissionSwitch(
                icon: Icons.restaurant,
                iconColor: VColors.primary,
                title: 'Öğün ve Kalori Takibi',
                value: _allowMeal,
                onChanged: (v) => setState(() => _allowMeal = v),
              ),
              _buildDivider(),
              _buildPermissionSwitch(
                icon: Icons.scale,
                iconColor: VColors.onSurfaceVariant,
                title: 'Vücut Kilosu ve Hedefler',
                value: _allowWeight,
                onChanged: (v) => setState(() => _allowWeight = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionSwitch({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: VText.labelMd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch(
            value: value,
            activeColor: VColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncAndExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Senkronizasyon & Aktarım', style: VText.headlineMd),
            Text('GÜNCEL', style: VText.labelCaps.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: VSpace.xs),
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
                decoration: const BoxDecoration(
                  color: VColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth_connected, color: VColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Son BLE Senkronizasyon', style: VText.labelMd),
                    Text(
                      'Bugün 14:15 • 284 KB aktarıldı',
                      style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: VColors.onSurface, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('BLE Senkronizasyonu başlatıldı.')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: VColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.outlineVariant.withAlpha(60)),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(VRadius.card)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veri arşivi dışa aktarılıyor (CSV/JSON)...')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(VRadius.sm),
                        ),
                        child: const Icon(Icons.download, color: VColors.secondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verileri Dışa Aktar', style: VText.labelMd),
                            Text('CSV / JSON formatında arşivi indir', style: VText.bodyMd.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: VColors.onSurfaceVariant, size: 20),
                    ],
                  ),
                ),
              ),
              _buildDivider(),
              InkWell(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(VRadius.card)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifreli yerel snapshot oluşturuldu.')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(VRadius.sm),
                        ),
                        child: const Icon(Icons.security, color: VColors.tertiary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Şifreli Yerel Yedek Oluştur', style: VText.labelMd),
                            Text('Sadece bu cihazda açılabilecek snapshot', style: VText.bodyMd.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: VColors.onSurfaceVariant, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RİSKLİ ALAN',
          style: VText.labelCaps.copyWith(color: VColors.error, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(VSpace.margin),
          decoration: BoxDecoration(
            color: VColors.errorContainer.withAlpha(60),
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(color: VColors.error.withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: VColors.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tüm Verileri Sıfırla ve Sil', style: VText.labelMd.copyWith(color: VColors.onErrorContainer)),
                        const SizedBox(height: 2),
                        Text(
                          'Cihaz içi tüm biyometrik arşivi kalıcı olarak siler ve VitaxBand bileklik eşleşmesini kaldırır. Geri alınamaz.',
                          style: VText.bodyMd.copyWith(color: VColors.onErrorContainer, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VSpace.margin),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VColors.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sm)),
                ),
                icon: const Icon(Icons.delete_forever, size: 20),
                label: const Text('Veri Kasasını Kalıcı Olarak Temizle'),
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: VColors.outlineVariant.withAlpha(40));
  }
}
