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

  /// Monotonically increasing token to detect when a newer [play] or [stop]
  /// call has superseded the current one. Each [play] and [stop] increments
  /// this value; in-progress async work checks it at await boundaries and
  /// abandons silently when it has been invalidated.
  int _playToken = 0;

  Future<void> play(String url, String mood) async {
    if (_disposed) return;
    if (url.isEmpty) return;

    Logger.debug('BGM play() called: mood=$mood token=$_playToken');
    final token = ++_playToken;
    _playingMood = mood;
    try {
      await _ensureCachedPlayer();
      await _fadeOutCached();
      if (_playToken != token || _disposed) return;

      await _cachedPlayer!.setUrl(url);
      await _cachedPlayer!.setLoopMode(LoopMode.all);
      await _cachedPlayer!.setVolume(0);

      // On web, play() may hang indefinitely when the browser blocks autoplay
      // without throwing an error. Use a timeout to detect this and set
      // pending state so onUserGesture() can retry.
      try {
        await _cachedPlayer!.play().timeout(_autoplayTimeout);
      } on TimeoutException {
        // Stop the player to cancel the orphaned play() call, then set
        // pending state so onUserGesture() → _gestureRetry() can retry
        // with the already-loaded source.
        unawaited(_cachedPlayer!.stop());
        _pendingUrl = url;
        _pendingMood = mood;
        _playingMood = null;
        isPlaying.value = false;
        Logger.info(
          'BGM play timed out (autoplay likely blocked): mood=$mood '
          '(will retry on user gesture)',
        );
        return;
      }
      if (_playToken != token || _disposed) return;

      await _fadeTo(_cachedPlayer!, _effectiveVolume);

      _pendingUrl = null;
      _pendingMood = null;
      currentMood.value = mood;
      isGenerating.value = false;
      isPlaying.value = true;
      Logger.info('BGM playback started: mood=$mood');
    } catch (e, st) {
      // If superseded by a newer play/stop, silently abandon.
      if (_playToken != token) return;
      if (_isAutoplayBlockedError(e)) {
        _pendingUrl = url;
        _pendingMood = mood;
        Logger.info(
          'BGM autoplay blocked: mood=$mood error=$e '
          '(will retry on user gesture)',
        );
      } else {
        Logger.warning('BGM playback failed: mood=$mood url=$url', e, st);
      }
      _playingMood = null;
      isGenerating.value = false;
      isPlaying.value = false;
    }
  }

  static const _autoplayTimeout = Duration(seconds: 3);

  void onGenerating(String mood) {
    if (_disposed) return;
    currentMood.value = mood;
    isGenerating.value = true;
  }

  Future<void> stop() async {
    if (_disposed) return;
    ++_playToken; // Invalidate any in-progress play().
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

  /// Whether playback is pending a user gesture to unlock autoplay.
  bool get hasPendingPlayback => _pendingUrl != null;

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
  ///
  /// The browser's autoplay policy requires audio playback to start from
  /// within a synchronous user-gesture handler. The previous [play] call
  /// loaded the source via setUrl but failed at [AudioPlayer.play] due to
  /// the policy. Here we call [AudioPlayer.play] **directly** — with NO
  /// preceding awaits — so the underlying DOM play() call happens within
  /// the browser's transient activation window.
  void onUserGesture() {
    if (_disposed || _retryingPendingPlayback) return;
    warmUp();
    final pendingUrl = _pendingUrl;
    final pendingMood = _pendingMood;
    if (pendingUrl == null || pendingMood == null) return;

    Logger.debug(
      'BGM onUserGesture: retrying pending playback mood=$pendingMood',
    );
    final player = _cachedPlayer;
    if (player == null) return;

    _pendingUrl = null;
    _pendingMood = null;
    unawaited(_gestureRetry(player, pendingUrl, pendingMood));
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

  /// Attempt to play by calling [AudioPlayer.play] as the very first async
  /// operation. The source was already loaded (via setUrl) in the earlier
  /// failed [play] attempt; calling play() here without intervening awaits
  /// ensures the underlying DOM `audioElement.play()` fires inside the
  /// browser's transient user-activation window.
  Future<void> _gestureRetry(
    AudioPlayer player,
    String url,
    String mood,
  ) async {
    _retryingPendingPlayback = true;
    _playingMood = mood;
    final token = ++_playToken;
    try {
      // FIRST await — no async work before this point.
      // The source was loaded by the previous failed play() via setUrl().
      await player.play();
      if (_playToken != token || _disposed) return;
      currentMood.value = mood;
      isGenerating.value = false;
      isPlaying.value = true;
      Logger.info('BGM gesture retry succeeded: mood=$mood');
      await _fadeTo(player, _effectiveVolume);
    } catch (e, st) {
      if (_playToken != token) return;
      if (_isAutoplayBlockedError(e)) {
        // Still blocked — re-queue for the next gesture.
        _pendingUrl = url;
        _pendingMood = mood;
        Logger.debug('BGM gesture retry still blocked, re-queued');
      } else {
        Logger.warning('BGM gesture retry failed', e, st);
      }
      _playingMood = null;
      isPlaying.value = false;
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
