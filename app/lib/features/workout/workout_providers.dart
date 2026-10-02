import 'dart:async';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models.dart';

/// Egzersiz kataloğu (paketli JSON).
final exerciseCatalogProvider = FutureProvider<ExerciseCatalog>(
  (ref) async => ExerciseCatalog.fromJson(
    await rootBundle.loadString('assets/data/exercises.json'),
  ),
);

final routinesProvider = FutureProvider<List<Routine>>(
  (ref) => ref.watch(workoutRepositoryProvider).routines(),
);

/// [range] = (başlangıç, bitiş-hariç). En yeni önce.
final sessionsProvider =
    FutureProvider.family<List<WorkoutSession>, (DateTime, DateTime)>(
      (ref, r) =>
          ref.watch(workoutRepositoryProvider).sessions(from: r.$1, to: r.$2),
    );

/// Son 120 gün (geçmiş ekranı, seri, haftalık hacim için).
final recentSessionsProvider = FutureProvider<List<WorkoutSession>>((ref) {
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  return ref
      .watch(workoutRepositoryProvider)
      .sessions(
        from: today.subtract(const Duration(days: 120)),
        to: today.add(const Duration(days: 1)),
      );
});

final sessionProvider = FutureProvider.family<WorkoutSession?, int>(
  (ref, id) => ref.watch(workoutRepositoryProvider).session(id),
);

final lastPerformanceProvider = FutureProvider.family<LastPerformance?, String>(
  (ref, exerciseId) =>
      ref.watch(workoutRepositoryProvider).lastPerformance(exerciseId),
);

final bestWeightProvider = FutureProvider.family<double?, String>(
  (ref, exerciseId) =>
      ref.watch(workoutRepositoryProvider).bestWeight(exerciseId),
);

/// Medya oluşturucu: üretimde ağdan çekip önbelleğe alır; testlerde yer tutucuyla değişir.
/// [controllable] true ise GIF elle oynatılır (hız ve duraklatma çalışır).
typedef MediaBuilder = Widget Function(
  String url, {
  double size,
  BoxFit fit,
  bool controllable,
  double speed,
  bool playing,
});

Widget _networkMedia(
  String url, {
  double size = 72,
  BoxFit fit = BoxFit.cover,
  bool controllable = false,
  double speed = 1,
  bool playing = true,
}) => controllable
    ? GifPlayer(url: url, size: size, fit: fit, speed: speed, playing: playing)
    : _cachedImage(url, size, fit);

Widget _cachedImage(String url, double size, BoxFit fit) => CachedNetworkImage(
  imageUrl: url,
  width: size,
  height: size,
  fit: fit,
  placeholder: (context, url) => Container(
    width: size,
    height: size,
    color: VColors.surfaceContainer,
    child: const Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  ),
  errorWidget: (context, url, error) => Container(
    width: size,
    height: size,
    color: VColors.surfaceContainer,
    child: Icon(PhosphorIconsRegular.barbell, color: VColors.outline, size: size * 0.4),
  ),
);

final exerciseMediaBuilderProvider = Provider<MediaBuilder>(
  (ref) => _networkMedia,
);

/// Rutin ve seans yazma işlemleri.
final workoutActionsProvider = Provider<WorkoutActions>(
  (ref) => WorkoutActions(ref),
);

class WorkoutActions {
  WorkoutActions(this._ref);
  final Ref _ref;

  void _refresh() {
    _ref.invalidate(routinesProvider);
    _ref.invalidate(recentSessionsProvider);
  }

  Future<int> saveRoutine(Routine r) async {
    final id = await _ref.read(workoutRepositoryProvider).saveRoutine(r);
    _refresh();
    return id;
  }

  Future<void> deleteRoutine(int id) async {
    await _ref.read(workoutRepositoryProvider).deleteRoutine(id);
    _refresh();
  }

  Future<void> deleteSession(int id) async {
    await _ref.read(workoutRepositoryProvider).deleteSession(id);
    _ref.invalidate(sessionProvider(id));
    _refresh();
  }

  /// Seans bittikten sonra listeleri tazele.
  void sessionFinished(int id) {
    _ref.invalidate(sessionProvider(id));
    _refresh();
    _ref.invalidate(lastPerformanceProvider);
    _ref.invalidate(bestWeightProvider);
  }
}

/// GIF'i önbellekten alıp çerçeve çerçeve oynatır; hız ve duraklatma destekler.
class GifPlayer extends StatefulWidget {
  const GifPlayer({
    super.key,
    required this.url,
    required this.size,
    this.fit = BoxFit.cover,
    this.speed = 1,
    this.playing = true,
  });
  final String url;
  final double size;
  final BoxFit fit;
  final double speed;
  final bool playing;

  @override
  State<GifPlayer> createState() => _GifPlayerState();
}

class _GifPlayerState extends State<GifPlayer> {
  ui.Codec? _codec;
  ui.Image? _frame;
  Timer? _timer;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.url);
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      if (!mounted) {
        codec.dispose();
        return;
      }
      _codec = codec;
      await _next();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _next() async {
    final codec = _codec;
    if (codec == null || !mounted) return;
    final f = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _frame = f.image);
    if (widget.playing) {
      final ms = (f.duration.inMilliseconds.clamp(20, 2000) / widget.speed)
          .round();
      _timer = Timer(Duration(milliseconds: ms), _next);
    }
  }

  @override
  void didUpdateWidget(GifPlayer old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) {
      _timer?.cancel();
      if (widget.playing) _next();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codec?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        width: widget.size,
        height: widget.size,
        color: VColors.surfaceContainer,
        child: Icon(
          PhosphorIconsRegular.barbell,
          color: VColors.outline,
          size: widget.size * 0.3,
        ),
      );
    }
    final f = _frame;
    if (f == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RawImage(image: f, fit: widget.fit),
    );
  }
}
