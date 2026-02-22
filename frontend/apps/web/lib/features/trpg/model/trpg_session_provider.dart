import 'dart:async';
import 'dart:convert';

import 'package:core_auth/core_auth.dart';
import 'package:core_genui/core_genui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'game_genui_providers.dart';
import 'text_paging_notifier.dart';
import 'trpg_visual_state.dart';

/// A single message in the TRPG conversation log.
class TrpgMessage {
  const TrpgMessage({required this.role, required this.text});

  /// 'user' or 'gm'.
  final String role;
  final String text;
}

/// Display mode for the novel game bottom area.
enum NovelDisplayMode {
  /// Showing text sentences one by one.
  paging,

  /// Showing a genui surface component (choices, roll, etc.).
  surface,

  /// Showing the free-text input field.
  input,

  /// GM is processing (streaming text).
  processing,
}

/// Manages the TRPG session state: messages, streaming, and GM turns.
///
/// Uses [GameContentGenerator] for SSE communication and
/// [A2uiMessageProcessor] for genui surface management.
class TrpgSessionNotifier {
  TrpgSessionNotifier(this._ref);

  final Ref _ref;

  final _messagesNotifier = ValueNotifier<List<TrpgMessage>>([]);
  final _isProcessingNotifier = ValueNotifier<bool>(false);
  final _visualStateNotifier = ValueNotifier<TrpgVisualState>(
    const TrpgVisualState(),
  );
  final _displayModeNotifier = ValueNotifier<NovelDisplayMode>(
    NovelDisplayMode.input,
  );

  final _subscriptions = <StreamSubscription<dynamic>>[];

  /// Whether the session has already been initialised.
  bool _initialised = false;

  /// Current session ID, stored for re-use in UI interaction callbacks.
  String? _sessionId;

  /// Text paging controller for sentence-by-sentence display.
  final textPager = TextPagingNotifier();

  /// Text buffer for accumulating streamed text within a turn.
  final _textBuffer = StringBuffer();

  /// Whether a game-surface is currently present (from genui processor).
  bool _hasSurface = false;

  /// Observable list of conversation messages.
  ValueListenable<List<TrpgMessage>> get messages => _messagesNotifier;

  /// Whether a GM turn is currently being processed/streamed.
  ValueListenable<bool> get isProcessing => _isProcessingNotifier;

  /// Visual state for the Flame game canvas.
  ValueNotifier<TrpgVisualState> get visualState => _visualStateNotifier;

  /// Current display mode for the novel game UI.
  ValueListenable<NovelDisplayMode> get displayMode => _displayModeNotifier;

  /// The [A2uiMessageProcessor] that manages genui surfaces.
  A2uiMessageProcessor get processor => _ref.read(gameProcessorProvider);

  /// Initialise (or re-initialise) for a new session.
  Future<void> initSession(String sessionId) async {
    if (_initialised) return;
    _initialised = true;
    _sessionId = sessionId;

    // Reset state for the new session
    _messagesNotifier.value = [];
    _isProcessingNotifier.value = false;
    _displayModeNotifier.value = NovelDisplayMode.processing;

    _setupSubscriptions();

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

  /// Set up listeners for GameContentGenerator and A2uiMessageProcessor.
  void _setupSubscriptions() {
    _cancelSubscriptions();

    final generator = _ref.read(gameContentGeneratorProvider);
    final proc = _ref.read(gameProcessorProvider);

    _subscriptions.addAll([
      generator.textResponseStream.listen(_onText),
      generator.gameStateStream.listen(_applyStateUpdate),
      generator.gameImageStream.listen(_onImage),
      generator.doneStream.listen((_) => _onDone()),
      generator.errorStream.listen(_onError),
      proc.surfaceUpdates.listen(_onSurfaceUpdate),
      proc.onSubmit.listen(_onUiInteraction),
    ]);
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  /// Reset session state so a new session can be started.
  void reset() {
    _cancelSubscriptions();
    _messagesNotifier.value = [];
    _isProcessingNotifier.value = false;
    _visualStateNotifier.value = const TrpgVisualState();
    _displayModeNotifier.value = NovelDisplayMode.input;
    _hasSurface = false;
    _textBuffer.clear();
    textPager.clear();
    _initialised = false;
    _sessionId = null;
  }

  /// Called when the user finishes reading all paged sentences.
  void onPagingComplete() {
    if (_hasSurface) {
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
    _hasSurface = false;
    _textBuffer.clear();
    textPager.clear();
    _displayModeNotifier.value = NovelDisplayMode.processing;

    // Don't show a user bubble for the automatic start turn
    if (inputType != 'start') {
      _messagesNotifier.value = [
        ..._messagesNotifier.value,
        TrpgMessage(role: 'user', text: inputText),
      ];
    }

    final user = _ref.read(currentUserProvider);
    final generator = _ref.read(gameContentGeneratorProvider);

    generator.sendTurn(
      sessionId: sessionId,
      inputType: inputType,
      inputText: inputText,
      authToken: user?.id,
    );
  }

  // -- Stream event handlers ------------------------------------------------

  void _onText(String content) {
    _textBuffer.write(content);
    _updateGmMessage(_textBuffer.toString());
  }

  void _onImage(String path) {
    _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
      backgroundImageUrl: _resolveStorageUrl(path),
    );
  }

  void _onDone() {
    _isProcessingNotifier.value = false;
    final fullText = _textBuffer.toString();
    if (fullText.trim().isEmpty) {
      onPagingComplete();
      return;
    }
    textPager.feed(fullText);
    _displayModeNotifier.value = NovelDisplayMode.paging;
  }

  void _onError(ContentGeneratorError error) {
    Logger.error('GM error: ${error.error}');
    _isProcessingNotifier.value = false;
    _displayModeNotifier.value = NovelDisplayMode.input;
  }

  void _onSurfaceUpdate(GenUiUpdate update) {
    switch (update) {
      case SurfaceAdded(:final surfaceId):
        if (surfaceId == 'game-surface') _hasSurface = true;
      case SurfaceRemoved(:final surfaceId):
        if (surfaceId == 'game-surface') _hasSurface = false;
      case SurfaceUpdated():
        break;
    }
  }

  /// Handle user interactions from genui surfaces (choices, roll, etc.).
  void _onUiInteraction(UserUiInteractionMessage message) {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    try {
      final decoded = jsonDecode(message.text) as Map<String, dynamic>;
      final userAction = decoded['userAction'] as Map<String, dynamic>?;
      if (userAction == null) return;

      final name = userAction['name'] as String? ?? '';
      final ctx = userAction['context'] as Map<String, dynamic>? ?? {};
      final inputType = ctx['inputType'] as String? ?? 'do';
      final inputText = ctx['inputText'] as String? ?? '';

      // Handle advance action (text paging) locally
      if (name == 'advance') {
        final advanced = textPager.advance();
        if (!advanced) onPagingComplete();
        return;
      }

      // All other actions trigger a new GM turn
      sendTurn(
        sessionId: sessionId,
        inputType: inputType,
        inputText: inputText,
      );
    } catch (e, st) {
      Logger.debug('Failed to parse UI interaction', e, st);
    }
  }

  // -- State management helpers ---------------------------------------------

  void _applyInitialState(Map<String, dynamic> state) {
    var vs = _visualStateNotifier.value;

    final location = state['location'] as String?;
    if (location != null) vs = vs.copyWith(locationName: location);

    final scene = state['scene_description'] as String?;
    if (scene != null) vs = vs.copyWith(sceneDescription: scene);

    final hp = state['hp'] as int?;
    if (hp != null) vs = vs.copyWith(hp: hp);

    final maxHp = state['max_hp'] as int?;
    if (maxHp != null) vs = vs.copyWith(maxHp: maxHp);

    final playerName = state['player_name'] as String?;
    if (playerName != null) vs = vs.copyWith(playerName: playerName);

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
      if (name != null) state = state.copyWith(locationName: name);
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
      messages[messages.length - 1] = TrpgMessage(role: 'gm', text: text);
    } else {
      messages.add(TrpgMessage(role: 'gm', text: text));
    }
    _messagesNotifier.value = messages;
  }

  void dispose() {
    _cancelSubscriptions();
    _messagesNotifier.dispose();
    _isProcessingNotifier.dispose();
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
