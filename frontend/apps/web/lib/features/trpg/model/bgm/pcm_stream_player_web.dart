import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'pcm_stream_player_interface.dart';

class PcmStreamPlayerImpl implements PcmStreamPlayer {
  PcmStreamPlayerImpl() {
    _audioContext = web.AudioContext();
    _gainNode = _audioContext.createGain();
    _gainNode.connect(_audioContext.destination);
    _nextScheduledTime = _audioContext.currentTime;
  }

  static const int _sampleRate = 48000;
  static const int _channels = 2;
  static const double _scheduleLeadTime = 0.03;

  late final web.AudioContext _audioContext;
  late final web.GainNode _gainNode;
  double _nextScheduledTime = 0;
  bool _disposed = false;

  @override
  Future<void> playChunk(Uint8List pcmInt16Data) async {
    if (_disposed || pcmInt16Data.isEmpty) return;

    _audioContext.resume();

    final frameCount = pcmInt16Data.lengthInBytes ~/ 4;
    if (frameCount <= 0) return;

    final left = Float32List(frameCount);
    final right = Float32List(frameCount);
    _deinterleavePcm(pcmInt16Data, left, right, frameCount);

    final buffer = _audioContext.createBuffer(
      _channels,
      frameCount,
      _sampleRate,
    );
    buffer.copyToChannel(left.toJS, 0);
    buffer.copyToChannel(right.toJS, 1);

    final source = _audioContext.createBufferSource();
    source.buffer = buffer;
    source.connect(_gainNode);

    final now = _audioContext.currentTime;
    if (_nextScheduledTime < now + _scheduleLeadTime) {
      _nextScheduledTime = now + _scheduleLeadTime;
    }

    source.start(_nextScheduledTime);
    _nextScheduledTime += frameCount / _sampleRate;
  }

  @override
  void setVolume(double volume) {
    if (_disposed) return;
    _gainNode.gain.value = volume.clamp(0.0, 1.0).toDouble();
  }

  @override
  void stop() {
    if (_disposed) return;
    _nextScheduledTime = _audioContext.currentTime + _scheduleLeadTime;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _audioContext.close();
  }

  static void _deinterleavePcm(
    Uint8List pcmInt16Data,
    Float32List left,
    Float32List right,
    int frameCount,
  ) {
    final byteData = pcmInt16Data.buffer.asByteData(
      pcmInt16Data.offsetInBytes,
      pcmInt16Data.lengthInBytes,
    );
    for (var i = 0; i < frameCount; i++) {
      final offset = i * 4;
      final l = byteData.getInt16(offset, Endian.little) / 32768.0;
      final r = byteData.getInt16(offset + 2, Endian.little) / 32768.0;
      left[i] = l.clamp(-1.0, 1.0).toDouble();
      right[i] = r.clamp(-1.0, 1.0).toDouble();
    }
  }
}

PcmStreamPlayer createPcmStreamPlayer() => PcmStreamPlayerImpl();
