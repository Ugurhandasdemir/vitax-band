import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/nutrition_calc.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../data/models.dart';
import '../band/band_status.dart';

const _activityLabels = {
  ActivityLevel.sedentary: 'Hareketsiz (masa başı)',
  ActivityLevel.light: 'Hafif Aktif (1-2 gün/hafta)',
  ActivityLevel.moderate: 'Orta Düzey (3-4 gün/hafta)',
  ActivityLevel.active: 'Çok Aktif (5-6 gün/hafta)',
  ActivityLevel.veryActive: 'Aşırı Aktif (günde 2 antrenman)',
};

/// Profil ve Hedefler: biyometri, ana hedef, günlük kalori/makro, su, adım, birim.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Profile? _draft;

  void _set(Profile p) => setState(() => _draft = p);

  /// Sayı düzenleme penceresi. Geçersizse açık kalır ve uyarı gösterir.
  Future<double?> _askNumber({
    required String title,
    required String unit,
    required double initial,
    required double min,
    required double max,
    bool integer = false,
  }) {
    final c = TextEditingController(
      text: integer ? initial.round().toString() : initial.toString(),
    );
    String? error;
    return showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: VColors.surface,
          title: Text(title, style: VText.headlineMd),
          content: TextField(
            key: const ValueKey('edit-value'),
            controller: c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(suffixText: unit, errorText: error),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
                if (v == null || v < min || v > max) {
                  setSt(
                    () => error =
                        '${formatTr(min.round())} ile ${formatTr(max.round())} arasında bir değer gir',
                  );
                  return;
                }
                Navigator.of(ctx).pop(v);
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editHeight(Profile p) async {
    final imperial = p.units == Units.imperial;
    final v = await _askNumber(
      title: 'Boy',
      unit: imperial ? 'inç' : 'cm',
      initial: imperial ? (p.heightCm / 2.54).roundToDouble() : p.heightCm,
      min: imperial ? 40 : 100,
      max: imperial ? 100 : 250,
    );
    if (v != null) _set(p.copyWith(heightCm: imperial ? v * 2.54 : v));
  }

  Future<void> _editWeight(Profile p) async {
    final imperial = p.units == Units.imperial;
    final v = await _askNumber(
      title: 'Kilo',
      unit: weightUnit(p.units),
      initial: imperial ? kgToLb(p.weightKg) : p.weightKg,
      min: imperial ? 66 : 30,
      max: imperial ? 660 : 300,
    );
    if (v != null) _set(p.copyWith(weightKg: imperial ? lbToKg(v) : v));
  }

  Future<void> _editInt(
    Profile p, {
    required String title,
    required String unit,
    required int current,
    required int min,
    required int max,
    required Profile Function(int) apply,
  }) async {
    final v = await _askNumber(
      title: title,
      unit: unit,
      initial: current.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      integer: true,
    );
    if (v != null) _set(apply(v.round()));
  }

  Future<void> _pickActivity(Profile p) async {
    final picked = await showModalBottomSheet<ActivityLevel>(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VRadius.cardLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: VSpace.md),
            Text('Aktivite Seviyesi', style: VText.headlineMd),
            for (final e in _activityLabels.entries)
              ListTile(
                title: Text(e.value, style: VText.bodyLgMedium),
                trailing: e.key == p.activity
                    ? const Icon(Icons.check, color: VColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(e.key),
              ),
            const SizedBox(height: VSpace.sm),
          ],
        ),
      ),
    );
    if (picked != null) _set(p.copyWith(activity: picked));
  }

  Future<void> _save(Profile p) async {
    await ref.read(profileActionsProvider).save(p.copyWith(onboarded: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Kaydedildi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final loaded = ref.watch(profileProvider).value;
    _draft ??= loaded;
    final p = _draft;
    final band = ref.watch(bandStatusProvider);
    if (p == null) {
      return const VDetailScaffold(
        title: 'Profil ve Hedefler',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final u = p.units;
    final imperial = u == Units.imperial;
    final (ft, inch) = cmToFeetInches(p.heightCm);
    final proteinKcal = p.proteinGoal * 4;
    final carbsKcal = p.carbsGoal * 4;
    final fatKcal = p.fatGoal * 9;

    return VDetailScaffold(
      key: const ValueKey('screen-profile'),
      title: 'Profil ve Hedefler',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          VCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: VColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 34,
                    color: VColors.primary,
                  ),
                ),
                const SizedBox(width: VSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name.isEmpty ? 'Kullanıcı' : p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VText.headlineLg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: VColors.tertiaryFixed,
                              borderRadius: BorderRadius.circular(VRadius.pill),
                            ),
                            child: Text(
                              'Aktif',
                              style: VText.microTag.copyWith(
                                color: VColors.tertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.watch_outlined,
                            size: 16,
                            color: VColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            band.connected
                                ? 'VİTAXBAND EŞLEŞTİ'
                                : 'VİTAXBAND EŞLEŞMEDİ',
                            style: VText.labelCaps.copyWith(
                              color: VColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          Text(
            'BİYOMETRİK ÖLÇÜMLER',
            style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant),
          ),
          const SizedBox(height: VSpace.sm),
          Row(
            children: [
              Expanded(
                child: _BioTile(
                  key: const ValueKey('tile-height'),
                  label: 'BOY',
                  value: imperial ? '$ft\' $inch"' : '${p.heightCm.round()}',
                  unit: imperial ? null : 'cm',
                  icon: Icons.height,
                  onTap: () => _editHeight(p),
                ),
              ),
              const SizedBox(width: VSpace.gutter),
              Expanded(
                child: _BioTile(
                  key: const ValueKey('tile-weight'),
                  label: 'KİLO',
                  value: weightValue(p.weightKg, u),
                  unit: weightUnit(u),
                  icon: Icons.monitor_weight_outlined,
                  onTap: () => _editWeight(p),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          Row(
            children: [
              Expanded(
                child: _BioTile(
                  key: const ValueKey('tile-age'),
                  label: 'YAŞ',
                  value: '${p.age}',
                  unit: 'yaş',
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _editInt(
                    p,
                    title: 'Yaş',
                    unit: 'yaş',
                    current: p.age,
                    min: 10,
                    max: 100,
                    apply: (v) => p.copyWith(age: v),
                  ),
                ),
              ),
              const SizedBox(width: VSpace.gutter),
              Expanded(
                child: _BioTile(
                  key: const ValueKey('tile-sex'),
                  label: 'CİNSİYET',
                  value: p.sex == Sex.male ? 'Erkek' : 'Kadın',
                  icon: p.sex == Sex.male ? Icons.male : Icons.female,
                  onTap: () => _set(
                    p.copyWith(sex: p.sex == Sex.male ? Sex.female : Sex.male),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          GestureDetector(
            key: const ValueKey('tile-activity'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _pickActivity(p),
            child: VCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: VColors.primaryFixed,
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: const Icon(
                      Icons.directions_run,
                      color: VColors.primary,
                    ),
                  ),
                  const SizedBox(width: VSpace.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AKTİVİTE SEVİYESİ',
                          style: VText.labelCaps.copyWith(
                            color: VColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _activityLabels[p.activity]!,
                          style: VText.bodyLgMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: VColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpace.md),
          Text(
            'ANA SAĞLIK HEDEFİ',
            style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant),
          ),
          const SizedBox(height: VSpace.sm),
          _GoalCard(
            keyName: 'lose',
            title: 'Kilo Ver',
            subtitle: 'Yağ yakımı odaklı kalori planı',
            chip: '-500 kcal',
            selected: p.goal == GoalType.lose,
            onTap: () => _set(p.copyWith(goal: GoalType.lose)),
          ),
          const SizedBox(height: VSpace.sm),
          _GoalCard(
            keyName: 'maintain',
            title: 'Kiloyu Koru',
            subtitle: 'Metabolik denge ve canlılık',
            chip: 'Denge',
            selected: p.goal == GoalType.maintain,
            onTap: () => _set(p.copyWith(goal: GoalType.maintain)),
          ),
          const SizedBox(height: VSpace.sm),
          _GoalCard(
            keyName: 'gain',
            title: 'Kas Kazan / Kilo Al',
            subtitle: 'Hipertrofi ve hacimlenme',
            chip: '+300 kcal',
            selected: p.goal == GoalType.gain,
            onTap: () => _set(p.copyWith(goal: GoalType.gain)),
          ),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Text(
                'GÜNLÜK HEDEFLER & MAKROLAR',
                style: VText.labelCaps.copyWith(
                  color: VColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _set(applyAutoPlan(p)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: VColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Otomatik Plan',
                      style: VText.labelCaps.copyWith(color: VColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GÜNLÜK ENERJİ İHTİYACI',
                            style: VText.labelCaps.copyWith(
                              color: VColors.onSurfaceVariant,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                formatTr(p.kcalGoal),
                                style: VText.displayLg.copyWith(fontSize: 38),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'kcal',
                                style: VText.bodyLg.copyWith(
                                  color: VColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      key: const ValueKey('edit-kcal'),
                      onTap: () => _editInt(
                        p,
                        title: 'Günlük Kalori Hedefi',
                        unit: 'kcal',
                        current: p.kcalGoal,
                        min: 1000,
                        max: 6000,
                        apply: (v) => p.copyWith(kcalGoal: v),
                      ),
                      child: Container(
                        width: VSpace.touchMin,
                        height: VSpace.touchMin,
                        decoration: const BoxDecoration(
                          color: VColors.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.gutter),
                _MacroBar(protein: proteinKcal, carbs: carbsKcal, fat: fatKcal),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Dot('Protein', VColors.secondary),
                    _Dot('Karb', VColors.tertiary),
                    _Dot('Yağ', VColors.primaryContainer),
                  ],
                ),
                const SizedBox(height: VSpace.gutter),
                Row(
                  children: [
                    Expanded(
                      child: _MacroTile(
                        key: const ValueKey('tile-protein'),
                        label: 'PROTEİN',
                        grams: p.proteinGoal,
                        kcal: proteinKcal,
                        total: p.kcalGoal,
                        color: VColors.secondary,
                        onTap: () => _editInt(
                          p,
                          title: 'Protein Hedefi',
                          unit: 'g',
                          current: p.proteinGoal,
                          min: 20,
                          max: 500,
                          apply: (v) => p.copyWith(proteinGoal: v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MacroTile(
                        key: const ValueKey('tile-carbs'),
                        label: 'KARB',
                        grams: p.carbsGoal,
                        kcal: carbsKcal,
                        total: p.kcalGoal,
                        color: VColors.tertiary,
                        onTap: () => _editInt(
                          p,
                          title: 'Karbonhidrat Hedefi',
                          unit: 'g',
                          current: p.carbsGoal,
                          min: 0,
                          max: 900,
                          apply: (v) => p.copyWith(carbsGoal: v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MacroTile(
                        key: const ValueKey('tile-fat'),
                        label: 'YAĞ',
                        grams: p.fatGoal,
                        kcal: fatKcal,
                        total: p.kcalGoal,
                        color: VColors.primaryContainer,
                        onTap: () => _editInt(
                          p,
                          title: 'Yağ Hedefi',
                          unit: 'g',
                          current: p.fatGoal,
                          min: 10,
                          max: 300,
                          apply: (v) => p.copyWith(fatGoal: v),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.gutter),
                Row(
                  children: [
                    Expanded(
                      child: _GoalTile(
                        key: const ValueKey('tile-water'),
                        label: 'GÜNLÜK SU',
                        value: formatLiters(p.waterGoalMl),
                        unit: 'Litre',
                        icon: Icons.water_drop_outlined,
                        iconBg: VColors.secondaryFixed,
                        iconColor: VColors.secondary,
                        onTap: () => _editInt(
                          p,
                          title: 'Günlük Su Hedefi',
                          unit: 'ml',
                          current: p.waterGoalMl,
                          min: 500,
                          max: 10000,
                          apply: (v) => p.copyWith(waterGoalMl: v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GoalTile(
                        key: const ValueKey('tile-steps'),
                        label: 'ADIM HEDEFİ',
                        value: formatTr(p.stepGoal),
                        unit: 'adım',
                        icon: Icons.directions_walk,
                        iconBg: VColors.tertiaryFixed,
                        iconColor: VColors.tertiary,
                        onTap: () => _editInt(
                          p,
                          title: 'Günlük Adım Hedefi',
                          unit: 'adım',
                          current: p.stepGoal,
                          min: 1000,
                          max: 50000,
                          apply: (v) => p.copyWith(stepGoal: v),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          Text(
            'BİRİM STANDARDI',
            style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant),
          ),
          const SizedBox(height: VSpace.sm),
          VCard(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ölçüm Birimleri', style: VText.bodyLgMedium),
                      Text(
                        'Ağırlık, boy ve sıvı hacimleri',
                        style: VText.microTag.copyWith(
                          fontWeight: FontWeight.w500,
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: Row(
                      children: [
                        for (final (unit, label) in [
                          (Units.metric, 'Metrik (kg, cm)'),
                          (Units.imperial, 'Imperial (lb, ft)'),
                        ])
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _set(p.copyWith(units: unit)),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: unit == u
                                      ? VColors.surfaceContainerLowest
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    VRadius.base,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: VText.microTag.copyWith(
                                    fontSize: 11,
                                    color: unit == u
                                        ? VColors.onSurface
                                        : VColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: VColors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.button),
                ),
              ),
              onPressed: () => _save(p),
              icon: const Icon(
                Icons.check_circle_outline,
                color: VColors.onPrimary,
              ),
              label: Text(
                'Hedefleri Güncelle ve Kaydet',
                style: VText.labelMd.copyWith(color: VColors.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: VSpace.sm),
          Text(
            'Değişiklikler bu cihazda saklanır.',
            textAlign: TextAlign.center,
            style: VText.microTag.copyWith(
              fontWeight: FontWeight.w500,
              color: VColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BioTile extends StatelessWidget {
  const _BioTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.unit,
  });
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: VCard(
      padding: const EdgeInsets.all(VSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: VText.labelCaps.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: VColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: VText.headlineLg.copyWith(fontSize: 26)),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.chip,
    required this.selected,
    required this.onTap,
  });
  final String keyName;
  final String title;
  final String subtitle;
  final String chip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      key: ValueKey('goal-$keyName'),
      padding: const EdgeInsets.all(VSpace.md),
      decoration: BoxDecoration(
        color: selected ? VColors.primaryFixed : VColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(
          color: selected
              ? VColors.primaryFixed
              : VColors.surfaceContainerHighest,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: selected ? VColors.primary : VColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: selected
                ? const Icon(Icons.check, size: 18, color: VColors.onPrimary)
                : null,
          ),
          const SizedBox(width: VSpace.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: VText.bodyLgMedium.copyWith(
                    color: selected ? VColors.primary : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? VColors.primary : VColors.surfaceContainer,
              borderRadius: BorderRadius.circular(VRadius.sm),
            ),
            child: Text(
              chip,
              style: VText.microTag.copyWith(
                color: selected ? VColors.onPrimary : VColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  final int protein;
  final int carbs;
  final int fat;

  @override
  Widget build(BuildContext context) {
    final total = protein + carbs + fat;
    int flex(int v) => total == 0 ? 1 : (v * 100 ~/ total).clamp(1, 100);
    return ClipRRect(
      borderRadius: BorderRadius.circular(VRadius.pill),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Expanded(
              flex: flex(protein),
              child: Container(color: VColors.secondary),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: flex(carbs),
              child: Container(color: VColors.tertiary),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: flex(fat),
              child: Container(color: VColors.primaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
      ),
    ],
  );
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    super.key,
    required this.label,
    required this.grams,
    required this.kcal,
    required this.total,
    required this.color,
    required this.onTap,
  });
  final String label;
  final int grams;
  final int kcal;
  final int total;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: VText.microTag.copyWith(color: color)),
          const SizedBox(height: 2),
          Text('$grams g', style: VText.headlineMd),
          Text(
            '$kcal kcal (%${percent(kcal, total)})',
            style: VText.microTag.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: VColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(VSpace.gutter),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: VText.microTag.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.headlineMd,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: VText.microTag.copyWith(
                        fontWeight: FontWeight.w500,
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
        ],
      ),
    ),
  );
}
