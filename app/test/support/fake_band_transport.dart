import 'dart:async';
import 'dart:typed_data';

import 'package:vitax_app/data/band/band_transport.dart';

class FakeBandTransport implements BandTransport {
  final _frames = StreamController<Uint8List>.broadcast();
  final _link = StreamController<BandLink>.broadcast();
  BandLink _current = BandLink.disconnected;
  final List<Uint8List> written = [];
  bool failConnect = false;

  @override
  Stream<Uint8List> get frames => _frames.stream;
  @override
  Stream<BandLink> get link => _link.stream;
  @override
  BandLink get currentLink => _current;

  void _set(BandLink l) {
    _current = l;
    _link.add(l);
  }

  @override
  Future<void> connect() async {
    _set(BandLink.connecting);
    if (failConnect) {
      _set(BandLink.disconnected);
      throw StateError('bağlanılamadı');
    }
    _set(BandLink.connected);
  }

  @override
  Future<void> disconnect() async => _set(BandLink.disconnected);

  @override
  Future<void> write(Uint8List data) async => written.add(data);

  /// Testte bantın bir paket göndermesi.
  void emit(String hex) => _frames.add(Uint8List.fromList([
        for (var i = 0; i < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ]..addAll(List.filled(20 - hex.length ~/ 2, 0))));

  /// Bant kendiliğinden koptu.
  void dropLink() => _set(BandLink.disconnected);

  List<String> get writtenOpcodes =>
      written.map((w) => w[0].toRadixString(16).padLeft(2, '0')).toList();
}
