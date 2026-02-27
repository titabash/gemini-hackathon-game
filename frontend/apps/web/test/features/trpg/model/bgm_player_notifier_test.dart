import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:web_app/features/trpg/model/bgm_player_notifier.dart';

/// Stub platform for [JustAudioPlatform] so that [AudioPlayer] operations
/// resolve immediately in unit tests without a native implementation.
class _StubJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return _StubAudioPlayerPlatform(request.id);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    return DisposeAllPlayersResponse();
  }
}

class _StubAudioPlayerPlatform extends AudioPlayerPlatform {
  _StubAudioPlayerPlatform(super.id);

  final _eventController = StreamController<PlaybackEventMessage>.broadcast();
  final _dataController = StreamController<PlayerDataMessage>.broadcast();

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      _dataController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    // Emit a "ready" event so AudioPlayer's internal state machine progresses
    // past the loading state. Without this, setUrl() hangs waiting for ready.
    _eventController.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        duration: null,
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
    return LoadResponse(duration: null);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    _dataController.add(PlayerDataMessage(playing: true));
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
    SetShuffleOrderRequest request,
  ) async => SetShuffleOrderResponse();

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
    SetSkipSilenceRequest request,
  ) async => SetSkipSilenceResponse();

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
    ConcatenatingInsertAllRequest request,
  ) async => ConcatenatingInsertAllResponse();

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
    ConcatenatingRemoveRangeRequest request,
  ) async => ConcatenatingRemoveRangeResponse();

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
    ConcatenatingMoveRequest request,
  ) async => ConcatenatingMoveResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async => SetAndroidAudioAttributesResponse();

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
  setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest request,
  ) async => SetAutomaticallyWaitsToMinimizeStallingResponse();

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
  setCanUseNetworkResourcesForLiveStreamingWhilePaused(
    SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest request,
  ) async => SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
    SetPreferredPeakBitRateRequest request,
  ) async => SetPreferredPeakBitRateResponse();

  @override
  Future<SetAllowsExternalPlaybackResponse> setAllowsExternalPlayback(
    SetAllowsExternalPlaybackRequest request,
  ) async => SetAllowsExternalPlaybackResponse();

  @override
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(
    AudioEffectSetEnabledRequest request,
  ) async => AudioEffectSetEnabledResponse();

  @override
  Future<AndroidLoudnessEnhancerSetTargetGainResponse>
  androidLoudnessEnhancerSetTargetGain(
    AndroidLoudnessEnhancerSetTargetGainRequest request,
  ) async => AndroidLoudnessEnhancerSetTargetGainResponse();

  @override
  Future<AndroidEqualizerGetParametersResponse> androidEqualizerGetParameters(
    AndroidEqualizerGetParametersRequest request,
  ) async => AndroidEqualizerGetParametersResponse(
    parameters: AndroidEqualizerParametersMessage(
      minDecibels: -10,
      maxDecibels: 10,
      bands: [],
    ),
  );

  @override
  Future<AndroidEqualizerBandSetGainResponse> androidEqualizerBandSetGain(
    AndroidEqualizerBandSetGainRequest request,
  ) async => AndroidEqualizerBandSetGainResponse();

  @override
  Future<SetWebCrossOriginResponse> setWebCrossOrigin(
    SetWebCrossOriginRequest request,
  ) async => SetWebCrossOriginResponse();

  @override
  Future<SetWebSinkIdResponse> setWebSinkId(
    SetWebSinkIdRequest request,
  ) async => SetWebSinkIdResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _eventController.close();
    await _dataController.close();
    return DisposeResponse();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BgmPlayerNotifier notifier;

  setUp(() {
    notifier = BgmPlayerNotifier();
  });

  tearDown(() {
    notifier.dispose();
  });

  group('BgmPlayerNotifier', () {
    test('onGenerating updates state', () {
      notifier.onGenerating('battle');

      expect(notifier.currentMood.value, 'battle');
      expect(notifier.isGenerating.value, isTrue);
    });

    test('setVolume clamps value', () {
      notifier.setVolume(1.5);
      expect(notifier.volume.value, 1.0);

      notifier.setVolume(-0.2);
      expect(notifier.volume.value, 0.0);
    });

    test('toggleMute toggles flag', () {
      expect(notifier.isMuted.value, isFalse);
      notifier.toggleMute();
      expect(notifier.isMuted.value, isTrue);
      notifier.toggleMute();
      expect(notifier.isMuted.value, isFalse);
    });

    test('stop resets transient state', () async {
      notifier.onGenerating('mysterious');

      await notifier.stop();

      expect(notifier.currentMood.value, isNull);
      expect(notifier.isGenerating.value, isFalse);
      expect(notifier.isPlaying.value, isFalse);
    });

    test('isRetryingPlayback is false initially', () {
      expect(notifier.isRetryingPlayback, isFalse);
    });

    test('warmUp does not throw on fresh notifier', () {
      // warmUp should not throw even though AudioPlayer may not have
      // a platform implementation in the test environment.
      // It only creates AudioPlayer lazily, so no platform call is made
      // unless play() is invoked.
      expect(() => notifier.warmUp(), returnsNormally);
    });

    test('warmUp is no-op after dispose', () {
      notifier.dispose();
      // Should not throw on disposed notifier.
      notifier.warmUp();
      // Re-create for tearDown.
      notifier = BgmPlayerNotifier();
    });

    test('onUserGesture without pending is no-op', () {
      // No pending URL → onUserGesture should not change any state.
      notifier.onUserGesture();

      expect(notifier.isRetryingPlayback, isFalse);
      expect(notifier.isPlaying.value, isFalse);
    });

    test('playingMood is null initially', () {
      expect(notifier.playingMood, isNull);
    });

    test('playingMood is null after stop', () async {
      notifier.onGenerating('battle');
      await notifier.stop();

      expect(notifier.playingMood, isNull);
    });

    test('onGenerating does not change playingMood', () {
      notifier.onGenerating('battle');

      expect(notifier.currentMood.value, 'battle');
      expect(notifier.playingMood, isNull);
    });

    test('play with empty url does not set playingMood', () async {
      await notifier.play('', 'battle');

      expect(notifier.playingMood, isNull);
    });
  });

  // Tests that call play() with a real URL need a stub AudioPlayer platform
  // so operations resolve immediately without a native implementation.
  group('BgmPlayerNotifier play() playingMood', () {
    late BgmPlayerNotifier n;

    setUp(() {
      JustAudioPlatform.instance = _StubJustAudioPlatform();
      n = BgmPlayerNotifier();
    });

    tearDown(() {
      n.dispose();
    });

    test('playingMood is set before first async operation', () async {
      // Register addTearDown first so play() completes before dispose,
      // even if expect throws and skips the await below.
      late Future<void> playFuture;
      addTearDown(() => playFuture);

      // Call play() — do NOT await yet.
      // _playingMood should be set synchronously before any async work
      // (i.e. before _ensureCachedPlayer yields).
      playFuture = n.play('https://example.com/bgm.mp3', 'exploration');

      // Immediately after the synchronous portion, playingMood is set.
      expect(n.playingMood, 'exploration');

      // Let play() complete so tearDown doesn't race with a dangling future.
      await playFuture;
    });
  });
}
