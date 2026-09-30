import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'band_transport.dart';

final _service = Guid('F0080001-0451-4000-B000-000000000000');
final _notify = Guid('F0080002-0451-4000-B000-000000000000');
final _write = Guid('F0080003-0451-4000-B000-000000000000');

/// flutter_blue_plus ile gerçek VitaxBand bağlantısı (Veepoo f008 kanalı).
/// Not: cihaz telefonun Bluetooth ayarlarında bağlıysa tarama görmez; önce "unut".
class BleBandTransport implements BandTransport {
  BleBandTransport({this.namePrefix = 'Vitax'});

  final String namePrefix;
  final _frames = StreamController<Uint8List>.broadcast();
  final _link = StreamController<BandLink>.broadcast();
  BandLink _current = BandLink.disconnected;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  StreamSubscription<dynamic>? _connSub;
  StreamSubscription<dynamic>? _notifySub;

  @override
  Stream<Uint8List> get frames => _frames.stream;
  @override
  Stream<BandLink> get link => _link.stream;
  @override
  BandLink get currentLink => _current;

  void _set(BandLink l) {
    if (_current == l) return;
    _current = l;
    _link.add(l);
  }

  Future<BluetoothDevice> _find() async {
    final found = Completer<BluetoothDevice>();
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        if (r.advertisementData.advName.startsWith(namePrefix) ||
            r.device.platformName.startsWith(namePrefix)) {
          if (!found.isCompleted) found.complete(r.device);
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
      return await found.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw StateError(
          'Bant bulunamadı. Telefon Bluetooth ayarlarında VitaxBand bağlıysa "Bu cihazı unut" yap.',
        ),
      );
    } finally {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  @override
  Future<void> connect() async {
    _set(BandLink.connecting);
    try {
      final d = await _find();
      _device = d;
      await d.connect(license: License.nonprofit, mtu: null);
      _connSub?.cancel();
      _connSub = d.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          _set(BandLink.disconnected);
        }
      });
      final services = await d.discoverServices();
      final svc = services.firstWhere(
        (s) => s.uuid == _service,
        orElse: () => throw StateError('Bant veri servisi (f008) bulunamadı'),
      );
      final notify = svc.characteristics.firstWhere((c) => c.uuid == _notify);
      _writeChar = svc.characteristics.firstWhere((c) => c.uuid == _write);
      await _notifySub?.cancel();
      _notifySub = notify.onValueReceived.listen(
        (v) => _frames.add(Uint8List.fromList(v)),
      );
      await notify.setNotifyValue(true);
      _set(BandLink.connected);
    } catch (e) {
      _set(BandLink.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _notifySub?.cancel();
    await _connSub?.cancel();
    await _device?.disconnect();
    _set(BandLink.disconnected);
  }

  @override
  Future<void> write(Uint8List data) async {
    final c = _writeChar;
    if (c == null) throw StateError('Bant bağlı değil');
    await c.write(data, withoutResponse: c.properties.writeWithoutResponse);
  }
}
