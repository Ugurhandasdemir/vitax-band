import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/nutrition_calc.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../../data/models.dart';

/// İlk açılış: ana hedef, beden bilgileri, (isteğe bağlı) bant eşleştirme.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _age = TextEditingController();
  GoalType _goal = GoalType.lose;
  Sex _sex = Sex.female;
  String? _error;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _age.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _continue() async {
    final h = _num(_height);
    final w = _num(_weight);
    final a = _num(_age);
    if (h == null ||
        w == null ||
        a == null ||
        h < 100 ||
        h > 250 ||
        w < 30 ||
        w > 300 ||
        a < 10 ||
        a > 100) {
      setState(() => _error = 'Boy, kilo ve yaş için geçerli değerler gir.');
      return;
    }
    final base = Profile(
      heightCm: h,
      weightKg: w,
      age: a.round(),
      sex: _sex,
      goal: _goal,
    );
    final planned = applyAutoPlan(base)
        .copyWith(onboarded: true, startWeightKg: w);
    await ref.read(profileActionsProvider).save(planned);
    await ref.read(weightActionsProvider).logWeight(w);
  }

  Future<void> _skip() async {
    final p = await ref.read(profileProvider.future);
    await ref.read(profileActionsProvider).save(p.copyWith(onboarded: true));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: VColors.background,
    body: SafeArea(
      child: ListView(
        key: const ValueKey('screen-onboarding'),
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 6,
                decoration: BoxDecoration(
                  color: VColors.primary,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
              ),
              for (var i = 0; i < 3; i++) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: VColors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                key: const ValueKey('onb-skip'),
                behavior: HitTestBehavior.opaque,
                onTap: _skip,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Atla',
                    style: VText.labelMd.copyWith(color: VColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.md),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: VColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(VRadius.cardLg),
                border: Border.all(color: VColors.surfaceContainerHighest),
              ),
              child: const Icon(
                PhosphorIconsRegular.heartbeat,
                size: 38,
                color: VColors.primary,
              ),
            ),
          ),
          const SizedBox(height: VSpace.md),
          Text(
            'BAŞLARKEN',
            textAlign: TextAlign.center,
            style: VText.labelCaps.copyWith(color: VColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            'Vital Precision\'a Hoş Geldin',
            textAlign: TextAlign.center,
            style: VText.headlineLg,
          ),
          const SizedBox(height: 6),
          Text(
            'Biyometrik verilerinle kişiselleşen akıllı sağlık ve egzersiz koçun.',
            textAlign: TextAlign.center,
            style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
          ),
          const SizedBox(height: VSpace.lg),
          _SectionTitle('1. Adım: Ana Sağlık Hedefin', 'ZORUNLU'),
          const SizedBox(height: VSpace.sm),
          _GoalOption(
            keyName: 'lose',
            icon: PhosphorIconsRegular.flame,
            iconColor: VColors.primary,
            title: 'Kilo Vermek & Yağ Yakmak',
            subtitle: 'Metabolik hız ve kalori açığı odağı',
            selected: _goal == GoalType.lose,
            onTap: () => setState(() => _goal = GoalType.lose),
          ),
          const SizedBox(height: VSpace.sm),
          _GoalOption(
            keyName: 'maintain',
            icon: PhosphorIconsRegular.heart,
            iconColor: VColors.secondary,
            title: 'Formu Korumak & Zinde Kalmak',
            subtitle: 'Günlük hareket ve dengeli nabız',
            selected: _goal == GoalType.maintain,
            onTap: () => setState(() => _goal = GoalType.maintain),
          ),
          const SizedBox(height: VSpace.sm),
          _GoalOption(
            keyName: 'gain',
            icon: PhosphorIconsRegular.barbell,
            iconColor: VColors.tertiary,
            title: 'Kas Kütlesi ve Kuvvet Kazanmak',
            subtitle: 'Hipertrofi ve toparlanma periyotları',
            selected: _goal == GoalType.gain,
            onTap: () => setState(() => _goal = GoalType.gain),
          ),
          const SizedBox(height: VSpace.lg),
          _SectionTitle('2. Adım: Beden Bilgileri', 'Hızlı Giriş'),
          const SizedBox(height: VSpace.sm),
          VCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _Field('BOY', 'cm', _height, 'onb-height')),
                    const SizedBox(width: VSpace.gutter),
                    Expanded(
                      child: _Field('KİLO', 'kg', _weight, 'onb-weight'),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.gutter),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _Field('YAŞ', 'yaş', _age, 'onb-age')),
                    const SizedBox(width: VSpace.gutter),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CİNSİYET',
                            style: VText.microTag.copyWith(
                              color: VColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: VColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(
                                VRadius.button,
                              ),
                            ),
                            child: Row(
                              children: [
                                for (final (s, label) in [
                                  (Sex.female, 'Kadın'),
                                  (Sex.male, 'Erkek'),
                                ])
                                  Expanded(
                                    child: GestureDetector(
                                      key: ValueKey('onb-sex-${s.name}'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => setState(() => _sex = s),
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _sex == s
                                              ? VColors.surfaceContainerLowest
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            VRadius.base,
                                          ),
                                        ),
                                        child: Text(
                                          label,
                                          style: VText.labelMd.copyWith(
                                            color: _sex == s
                                                ? VColors.primary
                                                : VColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.lg),
          _SectionTitle('3. Adım: Cihaz Eşleştirme', 'OPSİYONEL'),
          const SizedBox(height: VSpace.sm),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: VColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(VRadius.md),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.bluetooth,
                        color: VColors.secondary,
                      ),
                    ),
                    const SizedBox(width: VSpace.gutter),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VitaxBand Akıllı Bileklik',
                            style: VText.bodyLgMedium,
                          ),
                          Text(
                            'Bluetooth ile doğrudan telefonuna bağlanır, bulut gerektirmez.',
                            style: VText.bodyMd.copyWith(
                              color: VColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.gutter),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: VColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                VRadius.button,
                              ),
                            ),
                          ),
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bileklik eşleştirme kurulumdan sonra "Bilekliğim" bölümünde.',
                                  ),
                                ),
                              ),
                          icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 18),
                          label: Text(
                            'Bilekliği Şimdi Tara',
                            style: VText.labelMd.copyWith(
                              fontSize: 12,
                              color: VColors.onSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(VRadius.button),
                        ),
                        child: Text(
                          'Daha Sonra',
                          style: VText.labelMd.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: VColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.sparkle,
                    color: VColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: VSpace.gutter),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kişisel Algoritma Hazır',
                        style: VText.bodyLgMedium,
                      ),
                      Text(
                        'Seçimlerine göre kalori ve makro hedeflerin otomatik hesaplanır.',
                        style: VText.bodyMd.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: VSpace.gutter),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: VText.bodyMd.copyWith(color: VColors.error),
            ),
          ],
          const SizedBox(height: VSpace.md),
          SizedBox(
            height: 52,
            child: FilledButton(
              key: const ValueKey('onb-continue'),
              style: FilledButton.styleFrom(
                backgroundColor: VColors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.button),
                ),
              ),
              onPressed: _continue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Devam Et ve Hedefleri Oluştur',
                    style: VText.labelMd.copyWith(color: VColors.onPrimary),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    PhosphorIconsRegular.arrowRight,
                    size: 18,
                    color: VColors.onPrimary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(PhosphorIconsBold.lock, size: 14, color: VColors.tertiary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Verilerin yalnızca bu cihazda saklanır. Apple Health kullanılmaz.',
                  textAlign: TextAlign.center,
                  style: VText.microTag.copyWith(
                    fontWeight: FontWeight.w500,
                    color: VColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.tag);
  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: VText.headlineMd)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: VColors.surfaceContainer,
          borderRadius: BorderRadius.circular(VRadius.sm),
        ),
        child: Text(
          tag,
          style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
        ),
      ),
    ],
  );
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.keyName,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String keyName;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      key: ValueKey('onb-goal-$keyName'),
      padding: const EdgeInsets.all(VSpace.md),
      decoration: BoxDecoration(
        color: selected ? VColors.primaryFixed : VColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(
          color: selected ? VColors.primary : VColors.surfaceContainerHighest,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: VSpace.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VText.bodyLgMedium),
                Text(
                  subtitle,
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: selected ? VColors.primary : VColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: selected
                ? const Icon(PhosphorIconsRegular.check, size: 16, color: VColors.onPrimary)
                : null,
          ),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.unit, this.controller, this.keyName);
  final String label;
  final String unit;
  final TextEditingController controller;
  final String keyName;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
      ),
      const SizedBox(height: 4),
      TextField(
        key: ValueKey(keyName),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: VText.bodyLg,
        decoration: InputDecoration(
          isDense: true,
          suffixText: unit,
          filled: true,
          fillColor: VColors.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.button),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
}
