import 'dart:async';

import 'package:core_api/core_api.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api/gm_api.dart';
import 'text_paging_notifier.dart';
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

/// Display mode for the novel game bottom area.
enum NovelDisplayMode {
  /// Showing text sentences one by one.
  paging,

  /// Showing a surface component (choices, roll, etc.).
  surface,

  /// Showing the free-text input field.
  input,

  /// GM is processing (streaming text).
  processing,
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
  final _displayModeNotifier = ValueNotifier<NovelDisplayMode>(
    NovelDisplayMode.input,
  );
  StreamSubscription<GmEvent>? _subscription;

  /// Whether the session has already been initialised.
  bool _initialised = false;

  /// Text paging controller for sentence-by-sentence display.
  final textPager = TextPagingNotifier();

  /// Buffered surface event to show after paging completes.
  GmSurfaceUpdateEvent? _pendingSurface;

  /// Observable list of conversation messages.
  ValueListenable<List<TrpgMessage>> get messages => _messagesNotifier;

  /// Whether a GM turn is currently being processed/streamed.
  ValueListenable<bool> get isProcessing => _isProcessingNotifier;

  /// The latest surface update from GM (choiceGroup, rollPanel, etc.).
  ValueListenable<GmSurfaceUpdateEvent?> get currentSurface => _surfaceNotifier;

  /// Visual state for the Flame game canvas.
  ValueNotifier<TrpgVisualState> get visualState => _visualStateNotifier;

  /// Current display mode for the novel game UI.
  ValueListenable<NovelDisplayMode> get displayMode => _displayModeNotifier;

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
    _displayModeNotifier.value = NovelDisplayMode.processing;

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
    _displayModeNotifier.value = NovelDisplayMode.input;
    _pendingSurface = null;
    textPager.clear();
    _initialised = false;
  }

  /// Called when the user finishes reading all paged sentences.
  ///
  /// If a surface was buffered, switches to surface mode. Otherwise,
  /// switches to input mode.
  void onPagingComplete() {
    if (_pendingSurface != null) {
      _surfaceNotifier.value = _pendingSurface;
      _pendingSurface = null;
      _displayModeNotifier.value = NovelDisplayMode.surface;
    } else {
      _displayModeNotifier.value = NovelDisplayMode.input;
    }
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
    _pendingSurface = null;
    textPager.clear();
    _displayModeNotifier.value = NovelDisplayMode.processing;

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
            // Buffer surface for display after paging completes
            _pendingSurface = event;
            _updateGmMessageSurface(event);
          case GmStateUpdateEvent(:final data):
            _applyStateUpdate(data);
          case GmImageEvent(:final path):
            _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
              backgroundImageUrl: _resolveStorageUrl(path),
            );
          case GmDoneEvent():
            _isProcessingNotifier.value = false;
            _onStreamDone(buffer.toString());
          case GmErrorEvent(:final message):
            Logger.error('GM error: $message');
            _isProcessingNotifier.value = false;
            _displayModeNotifier.value = NovelDisplayMode.input;
        }
      },
      onError: (Object error) {
        Logger.error('GM stream error', error);
        _isProcessingNotifier.value = false;
        _displayModeNotifier.value = NovelDisplayMode.input;
      },
      onDone: () {
        _isProcessingNotifier.value = false;
      },
    );
  }

  /// Called when the GM stream completes. Feeds text to the pager.
  void _onStreamDone(String fullText) {
    if (fullText.trim().isEmpty) {
      // No text — go straight to surface or input
      onPagingComplete();
      return;
    }

    textPager.feed(fullText);
    _displayModeNotifier.value = NovelDisplayMode.paging;
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
        activeNpcs: npcs.cast<Map<String, dynamic>>().map((n) {
          final path = n['image_path'] as String?;
          return NpcVisual(
            name: n['name'] as String? ?? '',
            emotion: n['emotion'] as String?,
            imageUrl: path != null ? _resolveStorageUrl(path) : null,
          );
        }).toList(),
      );
    }

    _visualStateNotifier.value = state;
  }

  /// Convert a ``{bucket}/{objectPath}`` string into a public URL
  /// using the frontend Supabase client.
  String _resolveStorageUrl(String path) {
    final sep = path.indexOf('/');
    if (sep == -1) return path;
    final bucket = path.substring(0, sep);
    final objectPath = path.substring(sep + 1);
    final supabase = _ref.read(supabaseClientProvider);
    return supabase.storage.from(bucket).getPublicUrl(objectPath);
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
    _displayModeNotifier.dispose();
    textPager.dispose();
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
