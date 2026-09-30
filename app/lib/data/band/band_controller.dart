import 'dart:async';
import 'dart:typed_data';

import '../models.dart';
import '../repos/band_sample_repository.dart';
import 'band_transport.dart';
import 'veepoo_codec.dart';

class BandState {
  const BandState({
    this.link = BandLink.disconnected,
    this.battery,
    this.lastSync,
    this.steps,
    this.hr,
    this.lastBpm,
    this.error,
  });

  final BandLink link;
  final int? battery;
  final DateTime? lastSync;
  final int? steps;

  /// Canlı nabız açıkken son durum; kapalıyken null.
  final HrStatus? hr;
  final int? lastBpm;
  final String? error;

  bool get connected => link == BandLink.connected;

  BandState copyWith({
    BandLink? link,
    int? battery,
    DateTime? lastSync,
    int? steps,
    HrStatus? hr,
    bool clearHr = false,
    int? lastBpm,
    String? error,
    bool clearError = false,
  }) => BandState(
    link: link ?? this.link,
    battery: battery ?? this.battery,
    lastSync: lastSync ?? this.lastSync,
    steps: steps ?? this.steps,
    hr: clearHr ? null : (hr ?? this.hr),
    lastBpm: clearHr ? null : (lastBpm ?? this.lastBpm),
    error: clearError ? null : (error ?? this.error),
  );
}

/// Bant oturumu: parola el sıkışması, periyodik adım/pil yoklaması, canlı nabız.
/// Ham örnekler SQLite'a yazılır (yerel kasa).
class BandController {
  BandController({
    required this.transport,
    required this.repo,
    required DateTime Function() clock,
    Stream<void>? pollTicks,
    int Function()? timezoneOffsetMinutes,
  }) : _clock = clock,
       _tz =
           timezoneOffsetMinutes ??
           (() => DateTime.now().timeZoneOffset.inMinutes),
       _pollTicks =
           pollTicks ?? Stream<void>.periodic(const Duration(seconds: 60)) {
    _subs.add(transport.frames.listen(_onFrame));
    _subs.add(transport.link.listen(_onLink));
  }

  final BandTransport transport;
  final BandSampleRepository repo;
  final DateTime Function() _clock;
  final int Function() _tz;
  final Stream<void> _pollTicks;

  final _subs = <StreamSubscription<dynamic>>[];
  StreamSubscription<void>? _pollSub;
  final _states = StreamController<BandState>.broadcast();
  final _liveHr = StreamController<int>.broadcast();

  BandState _state = const BandState();
  bool _liveHrOn = false;
  bool _handshake = false;
  int? _lastStepTotal;

  BandState get state => _state;
  Stream<BandState> get states => _states.stream;

  /// Geçerli nabız değerleri (~1 Hz).
  Stream<int> get liveHr => _liveHr.stream;

  void _emit(BandState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  Future<void> connect() async {
    _handshake = false;
    _emit(_state.copyWith(link: BandLink.connecting, clearError: true));
    try {
      await transport.connect();
      await transport.write(
        buildPasswordPacket(now: _clock(), timezoneOffsetMinutes: _tz()),
      );
    } catch (e) {
      _emit(_state.copyWith(link: BandLink.disconnected, error: '$e'));
    }
  }

  Future<void> disconnect() async {
    if (_liveHrOn) await stopLiveHr();
    await transport.disconnect();
  }

  Future<void> startLiveHr() async {
    if (!_state.connected) return;
    _liveHrOn = true;
    _emit(_state.copyWith(hr: HrStatus.measuring));
    await transport.write(buildHrStart());
  }

  Future<void> stopLiveHr() async {
    _liveHrOn = false;
    _emit(_state.copyWith(clearHr: true));
    if (transport.currentLink == BandLink.connected) {
      await transport.write(buildHrStop());
    }
  }

  Future<void> pollNow() async {
    if (!_state.connected) return;
    await transport.write(buildBatteryRequest());
    await transport.write(buildStepsRequest());
  }

  void _onLink(BandLink l) {
    if (l == BandLink.disconnected) {
      _pollSub?.cancel();
      _pollSub = null;
      _liveHrOn = false;
      _handshake = false;
      _emit(_state.copyWith(link: BandLink.disconnected, clearHr: true));
    }
  }

  void _onFrame(Uint8List f) {
    switch (classifyFrame(f)) {
      case BandFrameKind.password:
        if (!_handshake) {
          _handshake = true;
          _emit(_state.copyWith(link: BandLink.connected));
          _pollSub ??= _pollTicks.listen((_) => pollNow());
          pollNow();
        }
      case BandFrameKind.battery:
        final b = parseBattery(f);
        if (b != null) _emit(_state.copyWith(battery: b.percent));
      case BandFrameKind.steps:
        final total = parseSteps(f);
        if (total == null) return;
        final now = _clock();
        if (total != _lastStepTotal) {
          _lastStepTotal = total;
          repo.insertSteps([StepSample(at: now, total: total)]);
        }
        _emit(_state.copyWith(steps: total, lastSync: now));
      case BandFrameKind.heartRate:
        if (!_liveHrOn) return;
        final h = parseHr(f);
        if (h.status == HrStatus.value) {
          repo.insertHr([HrSample(at: _clock(), bpm: h.bpm!)]);
          _liveHr.add(h.bpm!);
          _emit(_state.copyWith(hr: HrStatus.value, lastBpm: h.bpm));
        } else {
          _emit(_state.copyWith(hr: h.status));
        }
      case BandFrameKind.deviceInfo:
      case BandFrameKind.unknown:
        break;
    }
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _pollSub?.cancel();
    await _states.close();
    await _liveHr.close();
  }
}
