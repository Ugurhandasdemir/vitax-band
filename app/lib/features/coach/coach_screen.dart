import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../band/band_status.dart';
import 'health_insights_screen.dart';
import 'weekly_plan_screen.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<({bool isUser, String time, String text})> _messages = [
    (
      isUser: true,
      time: '14:18',
      text: 'Akşam yemeğinde dışarıda olacağım, tavsiye edebileceğin pratik bir alternatif var mı?',
    ),
  ];

  static const _suggestions = [
    'Proteinimi nasıl tamamlarım?',
    'Antrenmanı yarına erteleyeyim mi?',
    'VitaxBand verimi özetle',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add((
        isUser: true,
        time: '14:20',
        text: text.trim(),
      ));
    });
    _inputController.clear();

    // Simüle edilmiş AI cevabı
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _messages.add((
          isUser: false,
          time: '14:20',
          text: 'Harika bir soru! Dışarıda ızgara somon, biftek veya tavuk şiş tercih edip yanına bol yeşillik ve kinoa/esmer pirinç eklersen hem kalan makrolarını tamamlarsın hem de sindirimi yormazsın.',
        ));
      });
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final band = ref.watch(bandStatusProvider);
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final steps = ref.watch(stepsProvider(today)).value ?? 8432;
    final hr = ref.watch(latestHrProvider).value?.bpm ?? 58;

    return Scaffold(
      key: const ValueKey('screen-coach'),
      backgroundColor: VColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Status & Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: VColors.secondary,
                          borderRadius: BorderRadius.circular(VRadius.sm),
                        ),
                        child: const Icon(PhosphorIconsFill.robot, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text('Vital AI Koç', style: VText.headlineMd),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Haftalık Plan',
                        icon: const Icon(PhosphorIconsFill.calendarDots, color: VColors.primary, size: 22),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const WeeklyPlanScreen()),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'İçgörüler',
                        icon: const Icon(PhosphorIconsRegular.trendUp, color: VColors.secondary, size: 22),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const HealthInsightsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Metrics Status Strip (Scrollable)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: VSpace.margin),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: VColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: VColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(PhosphorIconsBold.lightning, size: 14, color: VColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'VitaxBand Canlı',
                          style: VText.labelCaps.copyWith(color: VColors.onSecondaryFixed, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MetricPill(icon: PhosphorIconsFill.moon, iconColor: VColors.secondary, label: 'Uyku 7s 12dk'),
                  const SizedBox(width: 8),
                  _MetricPill(icon: PhosphorIconsFill.heart, iconColor: VColors.error, label: 'Dinlenik $hr bpm'),
                  const SizedBox(width: 8),
                  _MetricPill(icon: PhosphorIconsRegular.personSimpleWalk, iconColor: VColors.tertiary, label: '$steps Adım'),
                  const SizedBox(width: 8),
                  _MetricPill(icon: PhosphorIconsRegular.forkKnife, iconColor: VColors.primary, label: '1.420 kcal'),
                ],
              ),
            ),
            const SizedBox(height: VSpace.sm),

            // Chat Messages Area
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.xs),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: Text('Bugün, 24 Ekim', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Initial Coach Briefing Bubble
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: VColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIconsFill.robot, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Vital AI Koç', style: VText.labelMd),
                                const SizedBox(width: 6),
                                Text('14:15', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(VSpace.md),
                              decoration: BoxDecoration(
                                color: VColors.surfaceContainerLowest,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bugünkü 8.432 adımın ve dün geceki derin uykun harika toparlanma sağladı! Öğle yemeğindeki kinoa ve tavuk salatası protein hedefine güçlü bir ivme kazandırdı.',
                                    style: VText.bodyMd.copyWith(height: 1.4),
                                  ),
                                  const SizedBox(height: VSpace.md),
                                  // Suggestion Bento Inside
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: VColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(VRadius.md),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(PhosphorIconsRegular.target, size: 16, color: VColors.primary),
                                                const SizedBox(width: 4),
                                                Text('Günün Önerisi', style: VText.labelCaps.copyWith(color: VColors.primary)),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: VColors.tertiaryFixed,
                                                borderRadius: BorderRadius.circular(VRadius.pill),
                                              ),
                                              child: Text(
                                                '%75 Hazır',
                                                style: VText.microTag.copyWith(color: VColors.onTertiaryFixed, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _InnerRecoItem(
                                          icon: PhosphorIconsRegular.barbell,
                                          iconColor: VColors.secondary,
                                          title: 'Aktif Toparlanma',
                                          desc: '45 dk hafif tempo koşu veya alt vücut kuvvet rutini.',
                                        ),
                                        const SizedBox(height: 6),
                                        _InnerRecoItem(
                                          icon: PhosphorIconsRegular.cookingPot,
                                          iconColor: VColors.tertiary,
                                          title: 'Akşam Menüsü Odağı',
                                          desc: 'Kalan 38g protein & 680 kcal. Fırın somon ve brokoli harika eşleşir.',
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 38,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: VColors.primary,
                                              foregroundColor: VColors.onPrimary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sm)),
                                            ),
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Aktif toparlanma antrenmanı başlatılıyor')),
                                              );
                                            },
                                            icon: const Icon(PhosphorIconsRegular.play, size: 16),
                                            label: const Text('Antrenmanı Başlat'),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpace.md),

                  // Chat Thread Items
                  for (final msg in _messages) ...[
                    Align(
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg.isUser ? VColors.primary : VColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(msg.isUser ? 16 : 2),
                            bottomRight: Radius.circular(msg.isUser ? 2 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: VText.bodyMd.copyWith(
                            color: msg.isUser ? VColors.onPrimary : VColors.onSurface,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Suggestions & Input Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: 6),
              decoration: BoxDecoration(
                color: VColors.surface.withOpacity(0.95),
                border: const Border(top: BorderSide(color: VColors.surfaceContainerHighest)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Suggestion Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in _suggestions) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8, bottom: 6),
                            child: ActionChip(
                              label: Text(s),
                              backgroundColor: VColors.surfaceContainerLowest,
                              labelStyle: VText.labelMd.copyWith(fontSize: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.pill)),
                              onPressed: () => _sendMessage(s),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Input Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(VRadius.card),
                      border: Border.all(color: VColors.surfaceContainerHighest),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.cameraPlus, size: 20, color: VColors.onSurfaceVariant),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fotoğraf analizi ve besin tarama açılıyor')),
                            );
                          },
                        ),
                        Expanded(
                          child: TextField(
                            key: const ValueKey('coach-input'),
                            controller: _inputController,
                            decoration: InputDecoration(
                              hintText: "AI Koç'a bir soru sorun...",
                              hintStyle: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant.withOpacity(0.6)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.microphone, size: 20, color: VColors.onSurfaceVariant),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sesli giriş hazırlanıyor')),
                            );
                          },
                        ),
                        IconButton(
                          key: const ValueKey('coach-send-btn'),
                          style: IconButton.styleFrom(
                            backgroundColor: VColors.primary,
                            foregroundColor: VColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sm)),
                          ),
                          icon: const Icon(PhosphorIconsRegular.paperPlaneTilt, size: 18),
                          onPressed: () => _sendMessage(_inputController.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(VRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: VText.microTag.copyWith(color: VColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InnerRecoItem extends StatelessWidget {
  const _InnerRecoItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(VRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VText.labelCaps.copyWith(color: VColors.onSurface)),
                const SizedBox(height: 2),
                Text(desc, style: VText.bodyMd.copyWith(fontSize: 12, color: VColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
