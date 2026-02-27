import 'dart:async';

import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// BGM player for cached URL playback.
class BgmPlayerNotifier {
  final currentMood = ValueNotifier<String?>(null);
  final isPlaying = ValueNotifier<bool>(false);
  final volume = ValueNotifier<double>(0.3);
  final isGenerating = ValueNotifier<bool>(false);
  final isMuted = ValueNotifier<bool>(false);

  AudioPlayer? _cachedPlayer;
  bool _disposed = false;
  String? _pendingUrl;
  String? _pendingMood;
  bool _retryingPendingPlayback = false;
  String? _playingMood;

  Future<void> play(String url, String mood) async {
    if (_disposed) return;
    if (url.isEmpty) return;
    _playingMood = mood;
    try {
      await _ensureCachedPlayer();
      await _fadeOutCached();

      await _cachedPlayer!.setUrl(url);
      await _cachedPlayer!.setLoopMode(LoopMode.all);
      await _cachedPlayer!.setVolume(0);
      await _cachedPlayer!.play();
      await _fadeTo(_cachedPlayer!, _effectiveVolume);

      _pendingUrl = null;
      _pendingMood = null;
      currentMood.value = mood;
      isGenerating.value = false;
      isPlaying.value = true;
    } catch (e, st) {
      if (_isAutoplayBlockedError(e)) {
        _pendingUrl = url;
        _pendingMood = mood;
        Logger.info(
          'BGM playback blocked by autoplay policy; waiting for user gesture',
        );
      } else {
        Logger.warning('BGM playback failed: mood=$mood url=$url', e, st);
      }
      _playingMood = null;
      isGenerating.value = false;
      isPlaying.value = false;
    }
  }

  void onGenerating(String mood) {
    if (_disposed) return;
    currentMood.value = mood;
    isGenerating.value = true;
  }

  Future<void> stop() async {
    if (_disposed) return;
    _pendingUrl = null;
    _pendingMood = null;
    await _stopCachedInternal();
    _playingMood = null;
    currentMood.value = null;
    isGenerating.value = false;
    isPlaying.value = false;
  }

  void setVolume(double value) {
    if (_disposed) return;
    volume.value = value.clamp(0.0, 1.0);
    _applyVolume();
  }

  void toggleMute() {
    if (_disposed) return;
    isMuted.value = !isMuted.value;
    _applyVolume();
    onUserGesture();
  }

  /// Whether a pending playback retry is currently in progress.
  bool get isRetryingPlayback => _retryingPendingPlayback;

  /// The mood that is actually playing audio right now.
  ///
  /// Unlike [currentMood], this is only set after a successful [play] call
  /// and cleared on [stop] or playback error. Use this to avoid restarting
  /// playback when the same mood is already playing.
  String? get playingMood => _playingMood;

  /// Pre-create the internal [AudioPlayer] so the browser AudioContext
  /// is initialized during a user gesture, unlocking autoplay.
  void warmUp() {
    if (_disposed) return;
    _cachedPlayer ??= AudioPlayer();
  }

  /// Retry a pending play request after any user interaction.
  void onUserGesture() {
    if (_disposed || _retryingPendingPlayback) return;
    warmUp();
    final pendingUrl = _pendingUrl;
    final pendingMood = _pendingMood;
    if (pendingUrl == null || pendingMood == null) return;
    _pendingUrl = null;
    _pendingMood = null;

    unawaited(_retryPendingPlayback(pendingUrl, pendingMood));
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final player = _cachedPlayer;
    if (player != null) {
      unawaited(player.dispose());
    }
    currentMood.dispose();
    isPlaying.dispose();
    volume.dispose();
    isGenerating.dispose();
    isMuted.dispose();
  }

  Future<void> _ensureCachedPlayer() async {
    _cachedPlayer ??= AudioPlayer();
    await _cachedPlayer!.setLoopMode(LoopMode.all);
  }

  Future<void> _stopCachedInternal() async {
    if (_cachedPlayer == null) return;
    await _cachedPlayer!.stop();
  }

  double get _effectiveVolume => isMuted.value ? 0 : volume.value;

  void _applyVolume() {
    if (_disposed) return;
    if (_cachedPlayer != null) {
      unawaited(_cachedPlayer!.setVolume(_effectiveVolume));
    }
  }

  Future<void> _fadeOutCached() async {
    final player = _cachedPlayer;
    if (player == null || !player.playing) return;
    await _fadeTo(player, 0);
    await player.stop();
  }

  Future<void> _fadeTo(AudioPlayer player, double target) async {
    const steps = 8;
    const delay = Duration(milliseconds: 40);
    final start = player.volume;
    final delta = (target - start) / steps;
    for (var i = 1; i <= steps; i++) {
      await player.setVolume(start + (delta * i));
      await Future<void>.delayed(delay);
    }
  }

  Future<void> _retryPendingPlayback(String url, String mood) async {
    if (_disposed) return;
    _retryingPendingPlayback = true;
    try {
      await play(url, mood);
    } finally {
      _retryingPendingPlayback = false;
    }
  }

  bool _isAutoplayBlockedError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('notallowederror') ||
        message.contains('user gesture') ||
        message.contains("didn't interact") ||
        message.contains('play() failed');
  }
}

final bgmPlayerProvider = Provider<BgmPlayerNotifier>((ref) {
  final notifier = BgmPlayerNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});
