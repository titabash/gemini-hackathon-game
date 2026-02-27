import 'dart:typed_data';

/// PCM streaming player abstraction.
abstract class PcmStreamPlayer {
  Future<void> playChunk(Uint8List pcmInt16Data);
  void setVolume(double volume);
  void stop();
  void dispose();
}
