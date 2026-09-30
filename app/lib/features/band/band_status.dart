import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/band/band_controller.dart';

export '../../data/band/band_controller.dart' show BandState;

/// UI'nin izlediği bant durumu; kaynak [BandController].
class BandStatusNotifier extends Notifier<BandState> {
  @override
  BandState build() {
    final c = ref.watch(bandControllerProvider);
    final sub = c.states.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    return c.state;
  }
}

final bandStatusProvider = NotifierProvider<BandStatusNotifier, BandState>(
  BandStatusNotifier.new,
);
