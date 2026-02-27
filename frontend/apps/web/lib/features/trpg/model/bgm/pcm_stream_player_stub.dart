import 'dart:typed_data';

import 'pcm_stream_player_interface.dart';

/// Non-web fallback stub.
class PcmStreamPlayerImpl implements PcmStreamPlayer {
  @override
  Future<void> playChunk(Uint8List pcmInt16Data) async {}

  @override
  void setVolume(double volume) {}

  @override
  void stop() {}

  @override
  void dispose() {}
}

PcmStreamPlayer createPcmStreamPlayer() => PcmStreamPlayerImpl();
