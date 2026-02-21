import 'dart:async';

import 'package:core_api/core_api.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api/gm_api.dart';
import 'trpg_visual_state.dart';

/// A single message in the TRPG conversation log.
class TrpgMessage {
  const TrpgMessage({
    required this.role,
    required this.text,
    this.surfaceComponent,
    this.surfaceData,
  });

  /// 'user' or 'gm'.
  final String role;
  final String text;

  /// If non-null, the GM returned a surface update for this message.
  final String? surfaceComponent;
  final Map<String, dynamic>? surfaceData;
}

/// Manages the TRPG session state: messages, streaming, and GM turns.
class TrpgSessionNotifier {
  TrpgSessionNotifier(this._ref);

  final Ref _ref;

  final _messagesNotifier = ValueNotifier<List<TrpgMessage>>([]);
  final _isProcessingNotifier = ValueNotifier<bool>(false);
  final _surfaceNotifier = ValueNotifier<GmSurfaceUpdateEvent?>(null);
  final _visualStateNotifier = ValueNotifier<TrpgVisualState>(
    const TrpgVisualState(),
  );
  StreamSubscription<GmEvent>? _subscription;

  /// Whether the session has already been initialised.
  bool _initialised = false;

  /// Observable list of conversation messages.
  ValueListenable<List<TrpgMessage>> get messages => _messagesNotifier;

  /// Whether a GM turn is currently being processed/streamed.
  ValueListenable<bool> get isProcessing => _isProcessingNotifier;

  /// The latest surface update from GM (choiceGroup, rollPanel, etc.).
  ValueListenable<GmSurfaceUpdateEvent?> get currentSurface => _surfaceNotifier;

  /// Visual state for the Flame game canvas.
  ValueNotifier<TrpgVisualState> get visualState => _visualStateNotifier;

  /// Initialise (or re-initialise) for a new session.
  ///
  /// Loads [current_state] from Supabase, applies it to the visual state,
  /// and sends the opening "start" turn to the GM backend.
  Future<void> initSession(String sessionId) async {
    if (_initialised) return;
    _initialised = true;

    // Reset state for the new session
    _messagesNotifier.value = [];
    _surfaceNotifier.value = null;
    _isProcessingNotifier.value = false;

    // Load session from DB to get initial_state
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final row = await supabase
          .from('sessions')
          .select('current_state, title')
          .eq('id', sessionId)
          .single();

      final currentState = row['current_state'] as Map<String, dynamic>?;
      if (currentState != null) {
        _applyInitialState(currentState);
      }
    } catch (e) {
      Logger.warning('Failed to load session initial state: $e');
    }

    // Auto-trigger GM opening narration
    sendTurn(sessionId: sessionId, inputType: 'start', inputText: 'start');
  }

  /// Reset session state so a new session can be started.
  void reset() {
    _subscription?.cancel();
    _messagesNotifier.value = [];
    _isProcessingNotifier.value = false;
    _surfaceNotifier.value = null;
    _visualStateNotifier.value = const TrpgVisualState();
    _initialised = false;
  }

  /// Send a player action to the GM.
  void sendTurn({
    required String sessionId,
    required String inputType,
    required String inputText,
  }) {
    if (_isProcessingNotifier.value) return;
    _isProcessingNotifier.value = true;
    _surfaceNotifier.value = null;

    // Don't show a user bubble for the automatic start turn
    if (inputType != 'start') {
      _messagesNotifier.value = [
        ..._messagesNotifier.value,
        TrpgMessage(role: 'user', text: inputText),
      ];
    }

    final sseFactory = _ref.read(sseClientFactoryProvider);
    final user = _ref.read(currentUserProvider);
    final authToken = user?.id;

    final gmStream = sendGmTurn(
      sseFactory: sseFactory,
      sessionId: sessionId,
      inputType: inputType,
      inputText: inputText,
      authToken: authToken,
    );

    final buffer = StringBuffer();

    _subscription?.cancel();
    _subscription = gmStream.listen(
      (event) {
        switch (event) {
          case GmTextEvent(:final content):
            buffer.write(content);
            _updateGmMessage(buffer.toString());
          case GmSurfaceUpdateEvent():
            _surfaceNotifier.value = event;
            _updateGmMessageSurface(event);
          case GmStateUpdateEvent(:final data):
            _applyStateUpdate(data);
          case GmDoneEvent():
            _isProcessingNotifier.value = false;
          case GmErrorEvent(:final message):
            Logger.error('GM error: $message');
            _isProcessingNotifier.value = false;
        }
      },
      onError: (Object error) {
        Logger.error('GM stream error', error);
        _isProcessingNotifier.value = false;
      },
      onDone: () {
        _isProcessingNotifier.value = false;
      },
    );
  }

  /// Apply initial game state from the scenario to [TrpgVisualState].
  void _applyInitialState(Map<String, dynamic> state) {
    var vs = _visualStateNotifier.value;

    final location = state['location'] as String?;
    if (location != null) {
      vs = vs.copyWith(locationName: location);
    }

    final scene = state['scene_description'] as String?;
    if (scene != null) {
      vs = vs.copyWith(sceneDescription: scene);
    }

    final hp = state['hp'] as int?;
    if (hp != null) {
      vs = vs.copyWith(hp: hp);
    }

    final maxHp = state['max_hp'] as int?;
    if (maxHp != null) {
      vs = vs.copyWith(maxHp: maxHp);
    }

    final playerName = state['player_name'] as String?;
    if (playerName != null) {
      vs = vs.copyWith(playerName: playerName);
    }

    _visualStateNotifier.value = vs;
  }

  void _applyStateUpdate(Map<String, dynamic> data) {
    var state = _visualStateNotifier.value;

    final sceneDesc = data['scene_description'] as String?;
    if (sceneDesc != null) {
      state = state.copyWith(sceneDescription: sceneDesc);
    }

    final location = data['location'] as Map<String, dynamic>?;
    if (location != null) {
      final name = location['location_name'] as String?;
      if (name != null) {
        state = state.copyWith(locationName: name);
      }
    }

    final hpDelta = data['hp_delta'] as int?;
    if (hpDelta != null) {
      final newHp = (state.hp + hpDelta).clamp(0, state.maxHp);
      state = state.copyWith(hp: newHp);
    }

    final npcs = data['active_npcs'] as List<dynamic>?;
    if (npcs != null) {
      state = state.copyWith(
        activeNpcs: npcs
            .cast<Map<String, dynamic>>()
            .map(
              (n) => NpcVisual(
                name: n['name'] as String? ?? '',
                emotion: n['emotion'] as String?,
              ),
            )
            .toList(),
      );
    }

    _visualStateNotifier.value = state;
  }

  void _updateGmMessage(String text) {
    final messages = [..._messagesNotifier.value];
    if (messages.isNotEmpty && messages.last.role == 'gm') {
      messages[messages.length - 1] = TrpgMessage(
        role: 'gm',
        text: text,
        surfaceComponent: messages.last.surfaceComponent,
        surfaceData: messages.last.surfaceData,
      );
    } else {
      messages.add(TrpgMessage(role: 'gm', text: text));
    }
    _messagesNotifier.value = messages;
  }

  void _updateGmMessageSurface(GmSurfaceUpdateEvent event) {
    final messages = [..._messagesNotifier.value];
    if (messages.isNotEmpty && messages.last.role == 'gm') {
      final last = messages.last;
      messages[messages.length - 1] = TrpgMessage(
        role: 'gm',
        text: last.text,
        surfaceComponent: event.component,
        surfaceData: event.data,
      );
    }
    _messagesNotifier.value = messages;
  }

  void dispose() {
    _subscription?.cancel();
    _messagesNotifier.dispose();
    _isProcessingNotifier.dispose();
    _surfaceNotifier.dispose();
    _visualStateNotifier.dispose();
  }
}

/// Provides [TrpgSessionNotifier] for managing GM conversation state.
///
/// Uses manual Provider because ValueNotifier-based state management
/// is not compatible with riverpod_generator.
final trpgSessionProvider = Provider<TrpgSessionNotifier>((ref) {
  final notifier = TrpgSessionNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
