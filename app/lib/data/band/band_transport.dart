import 'dart:typed_data';

enum BandLink { disconnected, connecting, connected }

/// Bantla ham 20 baytlık paket alışverişi. Gerçek uygulama BLE kullanır, testler sahte.
abstract class BandTransport {
  /// Bant bildirimleri (f008 notify).
  Stream<Uint8List> get frames;

  /// Bağlantı durumu değişiklikleri.
  Stream<BandLink> get link;

  BandLink get currentLink;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> write(Uint8List data);
}
