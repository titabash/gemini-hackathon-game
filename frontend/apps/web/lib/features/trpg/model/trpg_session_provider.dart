import 'dart:async';
import 'dart:convert';

import 'package:core_auth/core_auth.dart';
import 'package:core_genui/core_genui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'bgm_player_notifier.dart';
import 'change_event.dart';
import 'game_genui_providers.dart';
import 'node_player_notifier.dart';
import 'scene_node.dart';
import 'session_restore_helpers.dart';
import 'text_paging_notifier.dart';
import 'trpg_visual_state.dart';
import 'turn_message_parser.dart';

/// A single message in the TRPG conversation log.
class TrpgMessage {
  const TrpgMessage({
    required this.role,
    required this.text,
    this.turnNumber,
    this.speaker,
  });

  /// 'user' or 'gm'.
  final String role;
  final String text;

  /// The turn number this message belongs to, if available.
  final int? turnNumber;

  /// The speaker name for dialogue messages (GM role only).
  final String? speaker;
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

enum _TurnStreamEventKind {
  a2ui,
  text,
  image,
  nodesReady,
  assetReady,
  bgmUpdate,
  stateUpdate,
  done,
}

class _TurnStreamEvent {
  const _TurnStreamEvent({required this.kind, required this.payload});

  final _TurnStreamEventKind kind;
  final Object payload;
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
  final _isAwaitingUserActionNotifier = ValueNotifier<bool>(false);
  final _visualStateNotifier = ValueNotifier<TrpgVisualState>(
    const TrpgVisualState(),
  );
  final _displayModeNotifier = ValueNotifier<NovelDisplayMode>(
    NovelDisplayMode.input,
  );
  final _pendingChangesNotifier = ValueNotifier<List<ChangeEvent>>([]);

  final _subscriptions = <StreamSubscription<dynamic>>[];

  /// Whether the session has already been initialised.
  bool _initialised = false;

  /// Current session ID, stored for re-use in UI interaction callbacks.
  String? _sessionId;
  String? _scenarioId;

  /// Text paging controller for sentence-by-sentence display (legacy).
  final textPager = TextPagingNotifier();

  /// Node-based playback controller for visual novel pages.
  final nodePlayer = NodePlayerNotifier();

  /// Whether the current turn uses node-based playback.
  bool _useNodePlayer = false;

  /// Whether the current turn uses node-based playback (read-only).
  bool get useNodePlayer => _useNodePlayer;

  /// Text buffer for accumulating streamed text within a turn.
  final _textBuffer = StringBuffer();

  /// Whether a game-surface is currently present (from genui processor).
  bool _hasSurface = false;

  /// Debounce timer for saving current node index.
  Timer? _saveTimer;
  bool _currentTurnHasNodeBgmDirectives = false;
  List<SceneNode> _currentTurnNodes = const [];

  final Map<String, String> _bgmReadyUrlByMood = {};
  final List<_TurnStreamEvent> _bufferedTurnEvents = [];
  bool _hasStreamingGmMessage = false;
  bool _willAutoContinue = false;
  bool _bufferIncomingTurnEvents = false;
  bool _replayingBufferedTurnEvents = false;
  bool _isSessionEnded = false;

  /// Whether the session has ended (game over / victory / etc.).
  bool get isSessionEnded => _isSessionEnded;

  /// Observable list of conversation messages.
  ValueListenable<List<TrpgMessage>> get messages => _messagesNotifier;

  /// Whether a GM turn is currently being processed/streamed.
  ValueListenable<bool> get isProcessing => _isProcessingNotifier;

  /// Whether the current turn is waiting for player input.
  ValueListenable<bool> get isAwaitingUserAction =>
      _isAwaitingUserActionNotifier;

  /// Visual state for the Flame game canvas.
  ValueNotifier<TrpgVisualState> get visualState => _visualStateNotifier;

  /// Current display mode for the novel game UI.
  ValueListenable<NovelDisplayMode> get displayMode => _displayModeNotifier;

  /// Pending change events from the latest stateUpdate.
  ///
  /// Consumed by [ActionResultOverlayWidget] to display visual feedback.
  /// The list is replaced (not cleared) on each stateUpdate so listeners
  /// can detect every batch.
  ValueListenable<List<ChangeEvent>> get pendingChanges =>
      _pendingChangesNotifier;

  /// The [A2uiMessageProcessor] that manages genui surfaces.
  A2uiMessageProcessor get processor => _ref.read(gameProcessorProvider);

  /// Initialise (or re-initialise) for a new session.
  Future<void> initSession(String sessionId) async {
    if (_initialised) return;
    _initialised = true;
    _sessionId = sessionId;
    _scenarioId = null;
    _bgmReadyUrlByMood.clear();
    _currentTurnHasNodeBgmDirectives = false;
    _currentTurnNodes = const [];
    _bufferedTurnEvents.clear();
    _hasStreamingGmMessage = false;
    _willAutoContinue = false;
    _bufferIncomingTurnEvents = false;
    _replayingBufferedTurnEvents = false;
    _isSessionEnded = false;

    // Reset state for the new session
    _messagesNotifier.value = [];
    _isProcessingNotifier.value = false;
    _isAwaitingUserActionNotifier.value = false;
    _displayModeNotifier.value = NovelDisplayMode.processing;

    _setupSubscriptions();

    // Load session from DB to get initial_state and turn info
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final row = await supabase
          .from('sessions')
          .select(
            'current_state, current_turn_number, title, '
            'scenario_id, current_node_index, status',
          )
          .eq('id', sessionId)
          .single();

      final sessionStatus = row['status'] as String? ?? 'active';
      if (sessionStatus != 'active') {
        _isSessionEnded = true;
        Logger.info('Session $sessionId is $sessionStatus, read-only mode');
      }

      final currentState = row['current_state'] as Map<String, dynamic>?;
      if (currentState != null) {
        _applyInitialState(currentState);
      }

      final turnNumber = row['current_turn_number'] as int? ?? 0;
      _scenarioId = row['scenario_id'] as String?;
      if (turnNumber > 0) {
        final savedNodeIndex = row['current_node_index'] as int? ?? 0;
        final scenarioId = _scenarioId;
        await _restoreFromLastTurn(sessionId, scenarioId, savedNodeIndex);
      } else {
        // New session: auto-trigger GM opening narration
        sendTurn(sessionId: sessionId, inputType: 'start', inputText: 'start');
      }
    } catch (e) {
      Logger.warning('Failed to load session, falling back to start: $e');
      sendTurn(sessionId: sessionId, inputType: 'start', inputText: 'start');
    }
  }

  /// Restore session state from all turns stored in DB.
  ///
  /// Loads every turn for the session, converts past turns into message
  /// history via [parseTurnsToMessages], and sets up node-based playback
  /// for the latest turn.
  Future<void> _restoreFromLastTurn(
    String sessionId,
    String? scenarioId,
    int savedNodeIndex,
  ) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);

      // Parallel queries for all turns, backgrounds, and NPCs
      final results = await Future.wait([
        // All turns ordered chronologically
        supabase
            .from('turns')
            .select('turn_number, input_type, input_text, output')
            .eq('session_id', sessionId)
            .order('turn_number', ascending: true),
        // Scene backgrounds for this session
        supabase
            .from('scene_backgrounds')
            .select('id, scenario_id, session_id, image_path, description')
            .or(
              'session_id.eq.$sessionId'
              '${scenarioId != null ? ',scenario_id.eq.$scenarioId' : ''}',
            ),
        // NPCs: session-specific, then scenario fallback
        supabase
            .from('npcs')
            .select('name, image_path, emotion_images')
            .or(
              'session_id.eq.$sessionId'
              '${scenarioId != null ? ',scenario_id.eq.$scenarioId' : ''}',
            ),
      ]);

      final allTurnRows = (results[0] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (allTurnRows.isEmpty) {
        _displayModeNotifier.value = NovelDisplayMode.input;
        return;
      }

      // Split into past turns and the latest turn
      final pastTurns = allTurnRows.length > 1
          ? allTurnRows.sublist(0, allTurnRows.length - 1)
          : <Map<String, dynamic>>[];
      final lastTurn = allTurnRows.last;

      // Build message history from past turns
      final historyMessages = parseTurnsToMessages(pastTurns);

      // Add user message from the last turn (if not 'start')
      final lastInputType = lastTurn['input_type'] as String? ?? '';
      final lastInputText = lastTurn['input_text'] as String? ?? '';
      final lastTurnNumber = lastTurn['turn_number'] as int? ?? 0;
      if (lastInputType != 'start') {
        historyMessages.add(
          TrpgMessage(
            role: 'user',
            text: lastInputText,
            turnNumber: lastTurnNumber,
          ),
        );
      }

      _messagesNotifier.value = historyMessages;

      // Process the latest turn's output for node playback
      final output = lastTurn['output'] as Map<String, dynamic>?;
      if (output == null) {
        _displayModeNotifier.value = NovelDisplayMode.input;
        return;
      }

      // Parse nodes from output
      final rawNodes = output['nodes'] as List<dynamic>?;
      if (rawNodes == null || rawNodes.isEmpty) {
        _currentTurnHasNodeBgmDirectives = false;
        _currentTurnNodes = const [];
        // Legacy flat-text: add narration_text to message log
        final narrationText = output['narration_text'] as String?;
        if (narrationText != null && narrationText.isNotEmpty) {
          _addGmNodeMessages([
            TrpgMessage(
              role: 'gm',
              text: narrationText,
              turnNumber: lastTurnNumber,
            ),
          ]);
        }
        _restoreChoiceSurface(output);
        await _restoreBgmFromLastTurn(scenarioId, output);
        _displayModeNotifier.value = _hasSurface
            ? NovelDisplayMode.surface
            : NovelDisplayMode.input;
        return;
      }

      final nodes = rawNodes
          .cast<Map<String, dynamic>>()
          .map(SceneNode.fromJson)
          .toList();
      _currentTurnNodes = nodes;
      _currentTurnHasNodeBgmDirectives = nodes.any(
        (n) => normalizeMood(n.bgm) != null || n.bgmStop,
      );

      // Build asset maps using helpers
      final bgRows = (results[1] as List<dynamic>).cast<Map<String, dynamic>>();
      final npcRows = (results[2] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final bgAssets = buildBackgroundAssetMap(bgRows, _resolveStorageUrl);
      final npcAssets = buildNpcAssetMap(npcRows, _resolveStorageUrl);

      // Pre-register assets with NodePlayer
      for (final entry in bgAssets.entries) {
        nodePlayer.onAssetReady(entry.key, entry.value);
      }
      for (final entry in npcAssets.entries) {
        final npcName = entry.key;
        final npcEntry = entry.value;
        if (npcEntry.defaultUrl != null) {
          nodePlayer.onAssetReady('npc:$npcName:default', npcEntry.defaultUrl!);
        }
        for (final emotionEntry in npcEntry.emotionUrls.entries) {
          nodePlayer.onAssetReady(
            'npc:$npcName:${emotionEntry.key}',
            emotionEntry.value,
          );
        }
      }

      // Load nodes and set up playback
      _useNodePlayer = true;
      nodePlayer.loadNodes(nodes);

      // Fast-forward to saved node index
      final targetIndex = savedNodeIndex.clamp(0, nodes.length - 1);
      for (var i = 0; i < targetIndex; i++) {
        nodePlayer.advance();
      }

      // Apply visual state from the current node
      _applyNodeVisualState(nodePlayer.currentNode.value);

      // Add individual node messages to log for the latest turn
      final nodeMessages = nodes
          .map(
            (n) => TrpgMessage(
              role: 'gm',
              text: n.text,
              turnNumber: lastTurnNumber,
              speaker: n.speaker,
            ),
          )
          .toList();
      _addGmNodeMessages(nodeMessages);
      await _restoreBgmFromLastTurn(
        scenarioId,
        output,
        nodes: nodes,
        targetNodeIndex: targetIndex,
      );

      // Determine display mode
      final allNodesRead = targetIndex >= nodes.length - 1;
      if (allNodesRead) {
        _restoreChoiceSurface(output);
        _displayModeNotifier.value = _hasSurface
            ? NovelDisplayMode.surface
            : NovelDisplayMode.input;
      } else {
        _displayModeNotifier.value = NovelDisplayMode.paging;
      }
    } catch (e) {
      Logger.warning('Failed to restore session from last turn: $e');
      _displayModeNotifier.value = NovelDisplayMode.input;
    }
  }

  /// Restore choice surface from turn output if applicable.
  void _restoreChoiceSurface(Map<String, dynamic> output) {
    final decisionType = output['decision_type'] as String?;
    final choices = output['choices'] as List<dynamic>?;
    if (decisionType == 'choice' && choices != null && choices.isNotEmpty) {
      final proc = _ref.read(gameProcessorProvider);
      proc.handleMessage(
        A2uiMessage.fromJson({
          'surfaceUpdate': {
            'surfaceId': 'game-surface',
            'components': [
              {
                'id': 'root',
                'component': {
                  'choiceGroup': {'choices': choices, 'allowFreeInput': true},
                },
              },
            ],
          },
        }),
      );
      proc.handleMessage(
        A2uiMessage.fromJson({
          'beginRendering': {'surfaceId': 'game-surface', 'root': 'root'},
        }),
      );
    }
  }

  Future<void> _restoreBgmFromLastTurn(
    String? scenarioId,
    Map<String, dynamic> output, {
    List<SceneNode>? nodes,
    int? targetNodeIndex,
  }) async {
    if (scenarioId == null || scenarioId.isEmpty) return;
    final mood = nodes != null && targetNodeIndex != null
        ? resolveNodeBgmMoodAtIndex(nodes, targetNodeIndex)
        : normalizeMood(output['bgm_mood'] as String?);
    if (mood == null) {
      _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
        bgmMood: () => null,
      );
      await _ref.read(bgmPlayerProvider).stop();
      return;
    }

    try {
      final supabase = _ref.read(supabaseClientProvider);
      final cached = await supabase
          .from('bgm')
          .select('audio_path')
          .eq('scenario_id', scenarioId)
          .eq('mood', mood)
          .maybeSingle();

      final audioPath = cached?['audio_path'] as String?;
      if (audioPath == null || audioPath.isEmpty) return;
      final resolvedUrl = _resolveStorageUrl('generated-bgm/$audioPath');
      _bgmReadyUrlByMood[mood] = resolvedUrl;

      _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
        bgmMood: () => mood,
      );
      await _ref.read(bgmPlayerProvider).play(resolvedUrl, mood);
    } catch (e) {
      Logger.warning('Failed to restore BGM from cache: $e');
    }
  }

  /// Set up listeners for GameContentGenerator and A2uiMessageProcessor.
  void _setupSubscriptions() {
    _cancelSubscriptions();

    final generator = _ref.read(gameContentGeneratorProvider);
    final proc = _ref.read(gameProcessorProvider);

    _subscriptions.addAll([
      generator.a2uiMessageStream.listen(
        (message) => _handleIncomingTurnEvent(
          _TurnStreamEvent(kind: _TurnStreamEventKind.a2ui, payload: message),
        ),
      ),
      generator.textResponseStream.listen(
        (content) => _handleIncomingTurnEvent(
          _TurnStreamEvent(kind: _TurnStreamEventKind.text, payload: content),
        ),
      ),
      generator.gameStateStream.listen(
        (data) => _handleIncomingTurnEvent(
          _TurnStreamEvent(
            kind: _TurnStreamEventKind.stateUpdate,
            payload: data,
          ),
        ),
      ),
      generator.gameImageStream.listen(
        (path) => _handleIncomingTurnEvent(
          _TurnStreamEvent(kind: _TurnStreamEventKind.image, payload: path),
        ),
      ),
      generator.nodesReadyStream.listen(
        (nodes) => _handleIncomingTurnEvent(
          _TurnStreamEvent(
            kind: _TurnStreamEventKind.nodesReady,
            payload: nodes,
          ),
        ),
      ),
      generator.assetReadyStream.listen(
        (data) => _handleIncomingTurnEvent(
          _TurnStreamEvent(
            kind: _TurnStreamEventKind.assetReady,
            payload: data,
          ),
        ),
      ),
      generator.bgmUpdateStream.listen(
        (data) => _handleIncomingTurnEvent(
          _TurnStreamEvent(kind: _TurnStreamEventKind.bgmUpdate, payload: data),
        ),
      ),
      generator.doneStream.listen(
        (data) => _handleIncomingTurnEvent(
          _TurnStreamEvent(kind: _TurnStreamEventKind.done, payload: data),
        ),
      ),
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
  ///
  /// IMPORTANT: [_initialised], [_sessionId], and [_scenarioId] are cleared
  /// synchronously (before any `await`) so that a subsequent [initSession]
  /// call in a cascade (`..reset()..initSession(id)`) can proceed without
  /// being blocked by the `if (_initialised) return` guard.
  Future<void> reset() async {
    // Clear the initialisation guard and session identity FIRST so that
    // a follow-up initSession() call is not rejected.
    _initialised = false;
    _sessionId = null;
    _scenarioId = null;

    _cancelSubscriptions();
    _ref.read(gameContentGeneratorProvider).cancelActiveTurn();
    _clearProcessorSurfaces();
    _saveTimer?.cancel();
    _messagesNotifier.value = [];
    _isProcessingNotifier.value = false;
    _isAwaitingUserActionNotifier.value = false;
    _visualStateNotifier.value = const TrpgVisualState();
    _displayModeNotifier.value = NovelDisplayMode.input;
    _pendingChangesNotifier.value = [];
    _hasSurface = false;
    _useNodePlayer = false;
    _textBuffer.clear();
    textPager.clear();
    nodePlayer.clear();
    _currentTurnNodes = const [];
    _bgmReadyUrlByMood.clear();
    _currentTurnHasNodeBgmDirectives = false;
    _bufferedTurnEvents.clear();
    _hasStreamingGmMessage = false;
    _willAutoContinue = false;
    _bufferIncomingTurnEvents = false;
    _replayingBufferedTurnEvents = false;
    _isSessionEnded = false;
    await _ref.read(bgmPlayerProvider).stop();
  }

  /// Remove all active genui surfaces from the processor.
  void _clearProcessorSurfaces() {
    final proc = _ref.read(gameProcessorProvider);
    for (final surfaceId in proc.surfaces.keys.toList()) {
      proc.handleMessage(SurfaceDeletion(surfaceId: surfaceId));
    }
  }

  /// Determines the display mode after paging completes.
  ///
  /// Pure function extracted for testability.
  /// Called after `_isSessionEnded` / `_willAutoContinue` checks have passed.
  static NovelDisplayMode resolvePostPagingMode({
    required bool isProcessing,
    required bool hasSurface,
  }) {
    if (isProcessing) return NovelDisplayMode.processing;
    if (hasSurface) return NovelDisplayMode.surface;
    return NovelDisplayMode.input;
  }

  /// Called when the user finishes reading all paged sentences / nodes.
  void onPagingComplete() {
    if (!_replayingBufferedTurnEvents && _replayNextBufferedTurn()) {
      Logger.debug('onPagingComplete: replaying next buffered turn');
      return;
    }
    if (_willAutoContinue) {
      Logger.debug('onPagingComplete: willAutoContinue, showing processing');
      _bufferIncomingTurnEvents = false;
      _displayModeNotifier.value = NovelDisplayMode.processing;
      return;
    }
    if (_isSessionEnded) {
      Logger.debug('onPagingComplete: session ended → input mode (read-only)');
      _clearProcessorSurfaces();
      _hasSurface = false;
      _displayModeNotifier.value = NovelDisplayMode.input;
      return;
    }
    final mode = resolvePostPagingMode(
      isProcessing: _isProcessingNotifier.value,
      hasSurface: _hasSurface,
    );
    Logger.debug(
      'onPagingComplete: resolved → $mode, '
      'isProcessing=${_isProcessingNotifier.value}, '
      'hasSurface=$_hasSurface',
    );
    _displayModeNotifier.value = mode;
  }

  /// Advance paging by one step (node or sentence).
  ///
  /// Delegates to [nodePlayer] or [textPager] depending on the current mode,
  /// and calls [onPagingComplete] when all pages have been shown.
  void advancePaging() {
    if (_useNodePlayer) {
      final advanced = nodePlayer.advance();
      if (advanced) {
        _applyNodeVisualState(nodePlayer.currentNode.value);
        _saveCurrentNodeIndex(nodePlayer.currentIndex);
      } else {
        onPagingComplete();
      }
    } else {
      final advanced = textPager.advance();
      if (!advanced) onPagingComplete();
    }
  }

  /// Send a player action to the GM.
  void sendTurn({
    required String sessionId,
    required String inputType,
    required String inputText,
  }) {
    if (_isSessionEnded) {
      Logger.info('sendTurn BLOCKED: session has ended');
      return;
    }
    if (_isProcessingNotifier.value && !_canAcceptUserTurnWhileStreaming()) {
      Logger.info(
        'sendTurn BLOCKED: isProcessing=${_isProcessingNotifier.value}, '
        'mode=${_displayModeNotifier.value}, hasSurface=$_hasSurface, '
        'awaiting=${_isAwaitingUserActionNotifier.value}',
      );
      return;
    }
    Logger.info(
      'sendTurn ACCEPTED: type=$inputType, text=$inputText, '
      'session=$sessionId',
    );
    _isProcessingNotifier.value = true;
    _isAwaitingUserActionNotifier.value = false;
    _hasSurface = false;
    _useNodePlayer = false;
    _currentTurnHasNodeBgmDirectives = false;
    _currentTurnNodes = const [];
    _textBuffer.clear();
    textPager.clear();
    nodePlayer.clear();
    _bufferedTurnEvents.clear();
    _hasStreamingGmMessage = false;
    _willAutoContinue = false;
    _bufferIncomingTurnEvents = false;
    _replayingBufferedTurnEvents = false;
    _displayModeNotifier.value = NovelDisplayMode.processing;

    // Reset node index for new turn
    _saveCurrentNodeIndex(0);

    // Don't show a user bubble for the automatic start turn
    if (inputType != 'start') {
      _messagesNotifier.value = [
        ..._messagesNotifier.value,
        TrpgMessage(role: 'user', text: inputText),
      ];
    }

    final accessToken = _ref.read(accessTokenProvider);
    final generator = _ref.read(gameContentGeneratorProvider);

    generator.sendTurn(
      sessionId: sessionId,
      inputType: inputType,
      inputText: inputText,
      authToken: accessToken,
    );
  }

  // -- Node index persistence ------------------------------------------------

  void _saveCurrentNodeIndex(int index) {
    if (_sessionId == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_sessionId == null) return;
      try {
        await _ref
            .read(supabaseClientProvider)
            .from('sessions')
            .update({'current_node_index': index})
            .eq('id', _sessionId!);
      } catch (e) {
        Logger.warning('Failed to save node index: $e');
      }
    });
  }

  // -- Stream event handlers ------------------------------------------------

  void _handleIncomingTurnEvent(_TurnStreamEvent event) {
    // While replaying buffered events for one turn, any newly arriving SSE
    // events belong to subsequent turns and must stay queued.
    if (_replayingBufferedTurnEvents) {
      _bufferedTurnEvents.add(event);
      return;
    }

    if (!_bufferIncomingTurnEvents && _shouldStartBufferingOnNextTurn(event)) {
      _bufferIncomingTurnEvents = true;
    }
    if (_bufferIncomingTurnEvents) {
      _bufferedTurnEvents.add(event);
      return;
    }
    _applyTurnStreamEvent(event);
  }

  bool _replayNextBufferedTurn() {
    if (_bufferedTurnEvents.isEmpty) return false;
    _bufferIncomingTurnEvents = false;
    _replayingBufferedTurnEvents = true;
    while (_bufferedTurnEvents.isNotEmpty) {
      final event = _bufferedTurnEvents.removeAt(0);
      _applyTurnStreamEvent(event);
      if (event.kind == _TurnStreamEventKind.done) {
        break;
      }
    }
    _replayingBufferedTurnEvents = false;
    return true;
  }

  void _applyTurnStreamEvent(_TurnStreamEvent event) {
    switch (event.kind) {
      case _TurnStreamEventKind.a2ui:
        _applyA2ui(event.payload as A2uiMessage);
        return;
      case _TurnStreamEventKind.text:
        _applyText(event.payload as String);
        return;
      case _TurnStreamEventKind.image:
        _applyImage(event.payload as String);
        return;
      case _TurnStreamEventKind.nodesReady:
        _applyNodesReady(event.payload as List<Map<String, dynamic>>);
        return;
      case _TurnStreamEventKind.assetReady:
        _applyAssetReady(event.payload as Map<String, dynamic>);
        return;
      case _TurnStreamEventKind.bgmUpdate:
        _applyBgmUpdate(event.payload as Map<String, dynamic>);
        return;
      case _TurnStreamEventKind.stateUpdate:
        _applyStateUpdate(event.payload as Map<String, dynamic>);
        return;
      case _TurnStreamEventKind.done:
        _applyDone(event.payload as Map<String, dynamic>);
        return;
    }
  }

  void _applyText(String content) {
    _textBuffer.write(content);
    _updateGmMessage(_textBuffer.toString());
  }

  void _applyA2ui(A2uiMessage message) {
    _ref.read(gameProcessorProvider).handleMessage(message);

    // Synchronously track game-surface presence.
    // The async _onSurfaceUpdate handler also updates _hasSurface, but during
    // synchronous replay of buffered events the microtask hasn't fired yet.
    // Without this, onPagingComplete() may read a stale _hasSurface and choose
    // the wrong displayMode (input instead of surface).
    switch (message) {
      case BeginRendering(:final surfaceId) when surfaceId == 'game-surface':
        _hasSurface = true;
      case SurfaceDeletion(:final surfaceId) when surfaceId == 'game-surface':
        _hasSurface = false;
      default:
        break;
    }
  }

  void _applyImage(String path) {
    // Node-based playback handles backgrounds via assetReady events
    if (_useNodePlayer) return;

    _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
      backgroundImageUrl: () => _resolveStorageUrl(path),
    );
  }

  void _applyNodesReady(List<Map<String, dynamic>> rawNodes) {
    _useNodePlayer = true;
    final nodes = rawNodes.map(SceneNode.fromJson).toList();
    _currentTurnNodes = nodes;
    _currentTurnHasNodeBgmDirectives = nodes.any(
      (n) => normalizeMood(n.bgm) != null || n.bgmStop,
    );
    nodePlayer.loadNodes(nodes);

    // Replace the streaming summary with individual node messages.
    // Remove the last GM message (streaming placeholder) if present.
    final messages = [..._messagesNotifier.value];
    if (_hasStreamingGmMessage &&
        messages.isNotEmpty &&
        messages.last.role == 'gm') {
      messages.removeLast();
    }
    _hasStreamingGmMessage = false;
    // Add each node as a separate message
    for (final node in nodes) {
      messages.add(
        TrpgMessage(role: 'gm', text: node.text, speaker: node.speaker),
      );
    }
    _messagesNotifier.value = messages;

    // Update visual state from the first node
    _applyNodeVisualState(nodePlayer.currentNode.value);

    _displayModeNotifier.value = NovelDisplayMode.paging;
  }

  void _applyAssetReady(Map<String, dynamic> data) {
    final key = data['key'] as String? ?? '';
    final path = data['path'] as String? ?? '';
    if (key.isNotEmpty && path.isNotEmpty) {
      final resolvedUrl = _resolveStorageUrl(path);
      nodePlayer.onAssetReady(key, resolvedUrl);
      Logger.debug('_applyAssetReady: key=$key resolvedUrl=$resolvedUrl');

      // Re-apply visual state if the current node needs this asset
      final currentBg =
          nodePlayer.currentNode.value?.background ??
          nodePlayer.effectiveBackground;
      final isNpcAsset = key.startsWith('npc:');
      if (currentBg == key || isNpcAsset) {
        _applyNodeVisualState(nodePlayer.currentNode.value);
      }
    }
  }

  void _applyBgmUpdate(Map<String, dynamic> data) {
    final mood = normalizeMood(data['mood'] as String?);
    if (mood == null) return;
    final player = _ref.read(bgmPlayerProvider);
    final generating = data['generating'] == true;

    Logger.debug(
      '_applyBgmUpdate: mood=$mood generating=$generating '
      'path=${data['path']} playingMood=${player.playingMood}',
    );

    if (generating) {
      player.onGenerating(mood);
      _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
        bgmMood: () => mood,
      );
      return;
    }

    final rawPath = data['path'] as String? ?? '';
    final resolved = _resolveMaybeStorageUrl(rawPath);
    if (resolved == null) return;
    _bgmReadyUrlByMood[mood] = resolved;

    if (_useNodePlayer && _currentTurnHasNodeBgmDirectives) {
      final activeMood = _activeNodeBgmMood();
      if (activeMood != null) {
        if (activeMood != mood && !_bgmReadyUrlByMood.containsKey(activeMood)) {
          // LLM output may drift between decision.bgm_mood and node.bgm.
          // Reuse the same asset for the node's active mood to avoid deadlock.
          Logger.warning(
            'BGM mood mismatch: event=$mood active=$activeMood path=$rawPath',
          );
          _bgmReadyUrlByMood[activeMood] = resolved;
        }
        _syncNodeBgm(nodePlayer.currentNode.value);
        return;
      }
      // activeMood is null: current node has no BGM directive yet.
      // Fall through to direct playback with the server-provided mood.
    }

    // If the same mood is already playing, just update the cached URL
    // without restarting playback to avoid an audible gap on turn transitions.
    if (player.playingMood == mood) {
      _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
        bgmMood: () => mood,
      );
      return;
    }

    _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
      bgmMood: () => mood,
    );
    unawaited(player.play(resolved, mood));
  }

  void _applyDone(Map<String, dynamic> data) {
    final requiresUserAction = data['requires_user_action'] == true;
    final isEnding = data['is_ending'] == true;
    _willAutoContinue = data['will_continue'] == true;
    if (isEnding) {
      _isSessionEnded = true;
      _willAutoContinue = false;
    }
    _isAwaitingUserActionNotifier.value =
        requiresUserAction && !_willAutoContinue && !isEnding;
    _isProcessingNotifier.value = _willAutoContinue;
    _hasStreamingGmMessage = false;
    Logger.debug(
      '_applyDone: willContinue=$_willAutoContinue, '
      'requiresAction=$requiresUserAction, isEnding=$isEnding, '
      'sessionEnded=$_isSessionEnded, '
      'hasSurface=$_hasSurface, replaying=$_replayingBufferedTurnEvents',
    );

    if (_useNodePlayer) {
      // Node-based: already in paging mode from _onNodesReady
      if (nodePlayer.nodeCount == 0) {
        _bufferIncomingTurnEvents = false;
        onPagingComplete();
      } else {
        _bufferIncomingTurnEvents = _willAutoContinue;
        // User already finished reading all nodes while waiting for done.
        // Re-evaluate the display mode now that isProcessing has been updated.
        if (_displayModeNotifier.value == NovelDisplayMode.processing) {
          onPagingComplete();
        }
      }
      return;
    }

    // Legacy flat-text path
    final fullText = _textBuffer.toString();
    if (fullText.trim().isEmpty) {
      _bufferIncomingTurnEvents = false;
      onPagingComplete();
      return;
    }
    textPager.feed(fullText);
    _displayModeNotifier.value = NovelDisplayMode.paging;
    _bufferIncomingTurnEvents = _willAutoContinue;
  }

  void _onError(ContentGeneratorError error) {
    Logger.error('GM error: ${error.error}');
    _isProcessingNotifier.value = false;
    _isAwaitingUserActionNotifier.value = false;
    _willAutoContinue = false;
    _bufferIncomingTurnEvents = false;
    _bufferedTurnEvents.clear();
    _displayModeNotifier.value = NovelDisplayMode.input;
  }

  void _onSurfaceUpdate(GenUiUpdate update) {
    switch (update) {
      case SurfaceAdded(:final surfaceId):
        Logger.debug('_onSurfaceUpdate: SurfaceAdded($surfaceId)');
        if (surfaceId == 'game-surface') {
          _hasSurface = true;
          if (_isProcessingNotifier.value) {
            _isAwaitingUserActionNotifier.value = true;
          }
        }
      case SurfaceRemoved(:final surfaceId):
        Logger.debug('_onSurfaceUpdate: SurfaceRemoved($surfaceId)');
        if (surfaceId == 'game-surface') _hasSurface = false;
      case SurfaceUpdated():
        break;
    }
  }

  /// Handle user interactions from genui surfaces (choices, roll, etc.).
  void _onUiInteraction(UserUiInteractionMessage message) {
    if (_isSessionEnded) {
      Logger.info('_onUiInteraction: session ended, ignoring');
      return;
    }
    final sessionId = _sessionId;
    if (sessionId == null) {
      Logger.info('_onUiInteraction: sessionId is null, ignoring');
      return;
    }

    try {
      final decoded = jsonDecode(message.text) as Map<String, dynamic>;
      final userAction = decoded['userAction'] as Map<String, dynamic>?;
      if (userAction == null) {
        Logger.info('_onUiInteraction: userAction is null');
        return;
      }

      final name = userAction['name'] as String? ?? '';
      final ctx = userAction['context'] as Map<String, dynamic>? ?? {};
      final inputType = ctx['inputType'] as String? ?? 'do';
      final inputText = ctx['inputText'] as String? ?? '';

      Logger.info(
        '_onUiInteraction: name=$name, inputType=$inputType, '
        'inputText=$inputText, isProcessing=${_isProcessingNotifier.value}',
      );

      // Handle advance action (text paging / node playback)
      if (name == 'advance') {
        advancePaging();
        return;
      }

      // All other actions trigger a new GM turn
      sendTurn(
        sessionId: sessionId,
        inputType: inputType,
        inputText: inputText,
      );
    } catch (e, st) {
      Logger.error('Failed to parse UI interaction', e, st);
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
    try {
      _applyStateUpdateBody(data);
    } catch (e, st) {
      Logger.warning('Error in _applyStateUpdate', e, st);
    }
  }

  void _applyStateUpdateBody(Map<String, dynamic> data) {
    final changeEvents = <ChangeEvent>[];
    var state = _visualStateNotifier.value;

    final sceneDesc = data['scene_description'] as String?;
    if (sceneDesc != null) {
      state = state.copyWith(sceneDescription: sceneDesc);
    }

    final location = data['location'] as Map<String, dynamic>?;
    if (location != null) {
      final name = location['location_name'] as String?;
      if (name != null) {
        // Only emit LocationChangedEvent when the location actually changes.
        // This prevents a cinematic blackout overlay on every stateUpdate that
        // merely echoes the current location (e.g. the very first turn).
        if (name != state.locationName) {
          changeEvents.add(LocationChangedEvent(locationName: name));
        }
        state = state.copyWith(locationName: name);
      }
    }

    // Apply stats delta to all stat keys
    final statsDelta = data['stats_delta'] as Map<String, dynamic>?;
    if (statsDelta != null) {
      final newStats = Map<String, int>.from(state.stats);
      for (final entry in statsDelta.entries) {
        final rawDelta = entry.value;
        final delta = rawDelta is int
            ? rawDelta
            : (rawDelta as num?)?.toInt() ?? 0;
        if (delta == 0) continue;
        final current = newStats[entry.key] ?? 0;
        final maxVal = state.maxStats['max_${entry.key}'];
        final updated = maxVal != null
            ? (current + delta).clamp(0, maxVal)
            : current + delta;
        newStats[entry.key] = updated;
        changeEvents.add(
          StatChangeEvent(
            statKey: entry.key,
            delta: delta,
            newValue: updated,
            maxValue: maxVal,
          ),
        );
      }
      state = state.copyWith(stats: newStats);

      // Sync legacy hp/maxHp fields
      final rawHpDelta = statsDelta['hp'];
      final hpDelta = rawHpDelta is int
          ? rawHpDelta
          : (rawHpDelta as num?)?.toInt();
      if (hpDelta != null) {
        final newHp = (state.hp + hpDelta).clamp(0, state.maxHp);
        state = state.copyWith(hp: newHp);
      }
    }

    // Status effects: add/remove
    final effectAdds = data['status_effect_adds'] as List<dynamic>?;
    final effectRemoves = data['status_effect_removes'] as List<dynamic>?;
    if (effectAdds != null || effectRemoves != null) {
      var effects = [...state.statusEffects];
      if (effectRemoves != null) {
        final toRemove = effectRemoves.cast<String>().toSet();
        effects = effects.where((e) => !toRemove.contains(e)).toList();
        for (final name in toRemove) {
          changeEvents.add(StatusEffectRemovedEvent(effectName: name));
        }
      }
      if (effectAdds != null) {
        for (final e in effectAdds.cast<String>()) {
          if (!effects.contains(e)) {
            effects.add(e);
            changeEvents.add(StatusEffectAddedEvent(effectName: e));
          }
        }
      }
      state = state.copyWith(statusEffects: effects);
    }

    // New items
    final newItems = data['new_items'] as List<dynamic>?;
    if (newItems != null) {
      final parsed = newItems.cast<Map<String, dynamic>>().map((m) {
        final itemName = m['name'] as String? ?? '';
        final desc = m['description'] as String? ?? '';
        final rawQty = m['quantity'];
        final qty = rawQty is int ? rawQty : (rawQty as num?)?.toInt() ?? 1;
        changeEvents.add(
          ItemAcquiredEvent(
            itemName: itemName,
            description: desc,
            quantity: qty,
          ),
        );
        return InventoryItem(
          name: itemName,
          description: desc,
          itemType: m['item_type'] as String? ?? '',
          quantity: qty,
        );
      }).toList();
      state = state.copyWith(items: [...state.items, ...parsed]);
    }

    // Removed items
    final removedItems = data['removed_items'] as List<dynamic>?;
    if (removedItems != null) {
      final toRemove = removedItems.cast<String>().toSet();
      state = state.copyWith(
        items: state.items.where((i) => !toRemove.contains(i.name)).toList(),
      );
      for (final name in toRemove) {
        changeEvents.add(ItemRemovedEvent(itemName: name));
      }
    }

    // Item updates (quantity delta, equip state)
    final itemUpdates = data['item_updates'] as List<dynamic>?;
    if (itemUpdates != null) {
      final items = [...state.items];
      for (final raw in itemUpdates.cast<Map<String, dynamic>>()) {
        final name = raw['name'] as String? ?? '';
        final idx = items.indexWhere((i) => i.name == name);
        if (idx < 0) continue;
        var item = items[idx];
        final rawQtyDelta = raw['quantity_delta'];
        final qtyDelta = rawQtyDelta is int
            ? rawQtyDelta
            : (rawQtyDelta as num?)?.toInt();
        if (qtyDelta != null) {
          item = item.copyWith(quantity: item.quantity + qtyDelta);
        }
        final equipped = raw['is_equipped'] as bool?;
        if (equipped != null) {
          item = item.copyWith(isEquipped: equipped);
        }
        items[idx] = item;
      }
      state = state.copyWith(items: items);
    }

    // Relationship changes (delta-based)
    final relChanges = data['relationship_changes'] as List<dynamic>?;
    if (relChanges != null) {
      final rels = [...state.relationships];
      for (final raw in relChanges.cast<Map<String, dynamic>>()) {
        final npcName = raw['npc_name'] as String? ?? '';
        final affinityDelta = _asInt(raw['affinity_delta']);
        final trustDelta = _asInt(raw['trust_delta']);
        final fearDelta = _asInt(raw['fear_delta']);
        final debtDelta = _asInt(raw['debt_delta']);
        final hasChange =
            affinityDelta != 0 ||
            trustDelta != 0 ||
            fearDelta != 0 ||
            debtDelta != 0;
        if (hasChange) {
          changeEvents.add(
            RelationshipChangedEvent(
              npcName: npcName,
              affinityDelta: affinityDelta,
              trustDelta: trustDelta,
              fearDelta: fearDelta,
              debtDelta: debtDelta,
            ),
          );
        }
        final idx = rels.indexWhere((r) => r.npcName == npcName);
        if (idx >= 0) {
          rels[idx] = rels[idx].copyWith(
            affinity: rels[idx].affinity + affinityDelta,
            trust: rels[idx].trust + trustDelta,
            fear: rels[idx].fear + fearDelta,
            debt: rels[idx].debt + debtDelta,
          );
        } else {
          rels.add(
            NpcRelationship(
              npcName: npcName,
              affinity: affinityDelta,
              trust: trustDelta,
              fear: fearDelta,
              debt: debtDelta,
            ),
          );
        }
      }
      state = state.copyWith(relationships: rels);
    }

    // Objective updates
    final objUpdates = data['objective_updates'] as List<dynamic>?;
    if (objUpdates != null) {
      final objs = [...state.objectives];
      for (final raw in objUpdates.cast<Map<String, dynamic>>()) {
        final title = raw['title'] as String? ?? '';
        final status = raw['status'] as String? ?? 'active';
        final desc = raw['description'] as String?;
        changeEvents.add(ObjectiveUpdatedEvent(title: title, status: status));
        final idx = objs.indexWhere((o) => o.title == title);
        if (idx >= 0) {
          objs[idx] = objs[idx].copyWith(status: status, description: desc);
        } else {
          objs.add(
            ObjectiveInfo(title: title, status: status, description: desc),
          );
        }
      }
      state = state.copyWith(objectives: objs);
    }

    // ノードモードでは nodes[].characters が NPC 表示の唯一の真実源。
    // stateUpdate の active_npcs（intents/dialogues 由来）はノードモードでは無視する。
    final npcs = data['active_npcs'] as List<dynamic>?;
    if (npcs != null && !_useNodePlayer) {
      final npcList = npcs.cast<Map<String, dynamic>>().map((n) {
        final path = n['image_path'] as String?;
        return NpcVisual(
          name: n['name'] as String? ?? '',
          emotion: n['emotion'] as String?,
          imageUrl: path != null ? _resolveStorageUrl(path) : null,
        );
      }).toList();
      Logger.debug(
        '_applyStateUpdate: activeNpcs=${npcList.map((n) => '${n.name}(${n.imageUrl != null ? "has_img" : "no_img"})').join(', ')}',
      );
      state = state.copyWith(activeNpcs: npcList);
    }

    _visualStateNotifier.value = state;

    // Emit change events for visual feedback
    if (changeEvents.isNotEmpty) {
      _pendingChangesNotifier.value = changeEvents;
    }
  }

  /// Safely convert a JSON value (int or double) to int.
  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  /// Update visual state from the current scene node.
  ///
  /// This method is called from:
  ///   - `_applyNodesReady` (when nodes first arrive)
  ///   - `_applyAssetReady` (when background/NPC assets are resolved)
  ///   - `nodePlayer.currentNode` listener (on page advance)
  ///
  /// NPC表示について:
  ///   ノードモード（_useNodePlayer=true）では nodes[].characters が唯一の真実源。
  ///   stateUpdate.active_npcs はノードモードでは activeNpcs に反映しない。
  ///   characters == null または [] の場合は NPC をクリア（非表示）。
  void _applyNodeVisualState(SceneNode? node) {
    if (node == null) return;
    var state = _visualStateNotifier.value;

    // Background: resolve from nodePlayer asset cache.
    // Only update backgroundImageUrl when we have an actual resolved URL.
    // Do NOT clear it when:
    //   - bg is null (node doesn't specify background): stateUpdate or
    //     legacy imageUpdate may have set it
    //   - resolvedUrl is null (assetReady hasn't arrived yet): keep
    //     whatever is currently displayed
    final bg = node.background ?? nodePlayer.effectiveBackground;
    if (bg != null) {
      final resolvedUrl = nodePlayer.resolvedAssetUrl(bg);
      if (resolvedUrl != null) {
        Logger.debug('_applyNodeVisualState: bg=$bg resolved=$resolvedUrl');
        state = state.copyWith(backgroundImageUrl: () => resolvedUrl);
      }
    }

    // Speaker: set from the current node
    state = state.copyWith(currentSpeaker: () => node.speaker);

    // Characters → activeNpcs
    // nodes[].characters がノードごとの NPC 表示の唯一の真実源。
    // null または [] の場合は NPC をクリア（非表示）。
    // stateUpdate.active_npcs はノードモードでは使用しない（_applyStateUpdateBody 参照）。
    final characters = node.characters ?? [];
    if (characters.isEmpty) {
      state = state.copyWith(activeNpcs: []);
    } else {
      final existingImages = {
        for (final npc in state.activeNpcs)
          if (npc.imageUrl != null) npc.name: npc.imageUrl,
      };
      state = state.copyWith(
        activeNpcs: characters.map((c) {
          // Priority: emotion-specific > default > existing
          final emotionUrl = c.expression != null
              ? nodePlayer.resolvedAssetUrl('npc:${c.npcName}:${c.expression}')
              : null;
          final defaultUrl = nodePlayer.resolvedAssetUrl(
            'npc:${c.npcName}:default',
          );
          return NpcVisual(
            name: c.npcName,
            emotion: c.expression,
            imageUrl: emotionUrl ?? defaultUrl ?? existingImages[c.npcName],
          );
        }).toList(),
      );
    }

    _visualStateNotifier.value = state;
    _syncNodeBgm(node);
  }

  void _syncNodeBgm(SceneNode? node) {
    if (!_useNodePlayer || node == null) return;

    final nodeMood = normalizeMood(node.bgm);
    final activeMood = _activeNodeBgmMood();
    final stopOnly = node.bgmStop && nodeMood == null;
    final player = _ref.read(bgmPlayerProvider);

    if (stopOnly) {
      _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
        bgmMood: () => null,
      );
      unawaited(player.stop());
      return;
    }

    if (activeMood == null) return;

    _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
      bgmMood: () => activeMood,
    );

    if (player.playingMood == activeMood) return;

    // Skip if a pending-play retry is already in progress from
    // onUserGesture(); let that user-gesture-context play complete
    // to avoid a race condition where two concurrent play() calls
    // interfere with each other.
    if (player.isRetryingPlayback) return;

    // Skip if playback is already pending a user gesture retry.
    // Calling play() again would just fail with autoplay and could
    // corrupt the player's internal state (e.g., re-loading the URL
    // while _gestureRetry expects it to be loaded).
    if (player.hasPendingPlayback) return;

    final readyUrl = _bgmReadyUrlByMood[activeMood];
    if (readyUrl != null) {
      unawaited(player.play(readyUrl, activeMood));
    }
    // else: BGM URL will arrive via bgmUpdate event; do NOT call
    // onGenerating() here -- only the backend's explicit bgmGenerating
    // event should set the "generating" indicator.  Calling it
    // prematurely causes a false "BGM生成中..." on cache-hit because
    // nodesReady always arrives before bgmUpdate.
  }

  String? _activeNodeBgmMood() {
    if (_currentTurnNodes.isEmpty) return null;
    return resolveNodeBgmMoodAtIndex(
      _currentTurnNodes,
      nodePlayer.currentIndex,
    );
  }

  String _resolveStorageUrl(String path) {
    final sep = path.indexOf('/');
    if (sep == -1) return path;
    final bucket = path.substring(0, sep);
    final objectPath = path.substring(sep + 1);
    final supabase = _ref.read(supabaseClientProvider);
    return supabase.storage.from(bucket).getPublicUrl(objectPath);
  }

  String? _resolveMaybeStorageUrl(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return null;
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (!pathOrUrl.startsWith('generated-bgm/')) {
      return _resolveStorageUrl('generated-bgm/$pathOrUrl');
    }
    return _resolveStorageUrl(pathOrUrl);
  }

  void _updateGmMessage(String text) {
    final messages = [..._messagesNotifier.value];
    if (messages.isNotEmpty && messages.last.role == 'gm') {
      messages[messages.length - 1] = TrpgMessage(role: 'gm', text: text);
    } else {
      messages.add(TrpgMessage(role: 'gm', text: text));
    }
    _hasStreamingGmMessage = true;
    _messagesNotifier.value = messages;
  }

  /// Append multiple GM node messages to the message list.
  void _addGmNodeMessages(List<TrpgMessage> nodeMessages) {
    _messagesNotifier.value = [..._messagesNotifier.value, ...nodeMessages];
  }

  bool _canAcceptUserTurnWhileStreaming() {
    if (_isAwaitingUserActionNotifier.value) {
      return true;
    }
    if (_hasSurface) {
      return true;
    }
    final mode = _displayModeNotifier.value;
    return mode == NovelDisplayMode.surface || mode == NovelDisplayMode.input;
  }

  bool _shouldStartBufferingOnNextTurn(_TurnStreamEvent event) {
    // If a new nodesReady arrives while the player is still paging the current
    // node turn, it is a future turn and must be queued.
    if (event.kind != _TurnStreamEventKind.nodesReady ||
        _displayModeNotifier.value != NovelDisplayMode.paging ||
        !_useNodePlayer) {
      return false;
    }
    return nodePlayer.nodeCount > 0;
  }

  Future<void> dispose() async {
    _saveTimer?.cancel();
    _cancelSubscriptions();
    _clearProcessorSurfaces();
    _messagesNotifier.dispose();
    _isProcessingNotifier.dispose();
    _isAwaitingUserActionNotifier.dispose();
    _visualStateNotifier.dispose();
    _displayModeNotifier.dispose();
    _pendingChangesNotifier.dispose();
    textPager.dispose();
    nodePlayer.dispose();
    await _ref.read(bgmPlayerProvider).stop();
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
