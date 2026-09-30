import 'dart:async';
import 'dart:typed_data';

import 'band_transport.dart';

/// Bant yok (testler, masaüstü): bağlanma açık hatayla biter.
class OfflineBandTransport implements BandTransport {
  @override
  Stream<Uint8List> get frames => const Stream.empty();
  @override
  Stream<BandLink> get link => const Stream.empty();
  @override
  BandLink get currentLink => BandLink.disconnected;

  @override
  Future<void> connect() async =>
      throw StateError('Bu cihazda Bluetooth bant bağlantısı yok');
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> write(Uint8List data) async {}
}
