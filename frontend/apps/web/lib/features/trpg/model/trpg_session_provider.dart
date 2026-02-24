import 'dart:async';
import 'dart:convert';

import 'package:core_auth/core_auth.dart';
import 'package:core_genui/core_genui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

    // Load session from DB to get initial_state and turn info
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final row = await supabase
          .from('sessions')
          .select(
            'current_state, current_turn_number, title, '
            'scenario_id, current_node_index',
          )
          .eq('id', sessionId)
          .single();

      final currentState = row['current_state'] as Map<String, dynamic>?;
      if (currentState != null) {
        _applyInitialState(currentState);
      }

      final turnNumber = row['current_turn_number'] as int? ?? 0;
      if (turnNumber > 0) {
        final savedNodeIndex = row['current_node_index'] as int? ?? 0;
        final scenarioId = row['scenario_id'] as String?;
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
        _displayModeNotifier.value = _hasSurface
            ? NovelDisplayMode.surface
            : NovelDisplayMode.input;
        return;
      }

      final nodes = rawNodes
          .cast<Map<String, dynamic>>()
          .map(SceneNode.fromJson)
          .toList();

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

  /// Set up listeners for GameContentGenerator and A2uiMessageProcessor.
  void _setupSubscriptions() {
    _cancelSubscriptions();

    final generator = _ref.read(gameContentGeneratorProvider);
    final proc = _ref.read(gameProcessorProvider);

    _subscriptions.addAll([
      generator.textResponseStream.listen(_onText),
      generator.gameStateStream.listen(_applyStateUpdate),
      generator.gameImageStream.listen(_onImage),
      generator.nodesReadyStream.listen(_onNodesReady),
      generator.assetReadyStream.listen(_onAssetReady),
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
    _saveTimer?.cancel();
    _messagesNotifier.value = [];
    _isProcessingNotifier.value = false;
    _visualStateNotifier.value = const TrpgVisualState();
    _displayModeNotifier.value = NovelDisplayMode.input;
    _hasSurface = false;
    _useNodePlayer = false;
    _textBuffer.clear();
    textPager.clear();
    nodePlayer.clear();
    _initialised = false;
    _sessionId = null;
  }

  /// Called when the user finishes reading all paged sentences / nodes.
  void onPagingComplete() {
    if (_hasSurface) {
      _displayModeNotifier.value = NovelDisplayMode.surface;
    } else {
      _displayModeNotifier.value = NovelDisplayMode.input;
    }
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
    if (_isProcessingNotifier.value) return;
    _isProcessingNotifier.value = true;
    _hasSurface = false;
    _useNodePlayer = false;
    _textBuffer.clear();
    textPager.clear();
    nodePlayer.clear();
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

    final user = _ref.read(currentUserProvider);
    final generator = _ref.read(gameContentGeneratorProvider);

    generator.sendTurn(
      sessionId: sessionId,
      inputType: inputType,
      inputText: inputText,
      authToken: user?.id,
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

  void _onText(String content) {
    _textBuffer.write(content);
    _updateGmMessage(_textBuffer.toString());
  }

  void _onImage(String path) {
    // Node-based playback handles backgrounds via assetReady events
    if (_useNodePlayer) return;

    _visualStateNotifier.value = _visualStateNotifier.value.copyWith(
      backgroundImageUrl: () => _resolveStorageUrl(path),
    );
  }

  void _onNodesReady(List<Map<String, dynamic>> rawNodes) {
    _useNodePlayer = true;
    final nodes = rawNodes.map(SceneNode.fromJson).toList();
    nodePlayer.loadNodes(nodes);

    // Replace the streaming summary with individual node messages.
    // Remove the last GM message (streaming placeholder) if present.
    final messages = [..._messagesNotifier.value];
    if (messages.isNotEmpty && messages.last.role == 'gm') {
      messages.removeLast();
    }
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

  void _onAssetReady(Map<String, dynamic> data) {
    final key = data['key'] as String? ?? '';
    final path = data['path'] as String? ?? '';
    if (key.isNotEmpty && path.isNotEmpty) {
      nodePlayer.onAssetReady(key, _resolveStorageUrl(path));

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

  void _onDone() {
    // Guard against duplicate done (JSON event + SSE connection close)
    if (!_isProcessingNotifier.value) return;
    _isProcessingNotifier.value = false;

    if (_useNodePlayer) {
      // Node-based: already in paging mode from _onNodesReady
      if (nodePlayer.nodeCount == 0) {
        onPagingComplete();
      }
      return;
    }

    // Legacy flat-text path
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

    final statsDelta = data['stats_delta'] as Map<String, dynamic>?;
    if (statsDelta != null) {
      final hpDelta = statsDelta['hp'] as int?;
      if (hpDelta != null) {
        final newHp = (state.hp + hpDelta).clamp(0, state.maxHp);
        state = state.copyWith(hp: newHp);
      }
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

  /// Update visual state from the current scene node.
  void _applyNodeVisualState(SceneNode? node) {
    if (node == null) return;
    var state = _visualStateNotifier.value;

    // Background: resolve from nodePlayer asset cache.
    // Always set backgroundImageUrl so any wrongly-set value from _onImage
    // (which fires before nodesReady) gets overridden.
    final bg = node.background ?? nodePlayer.effectiveBackground;
    if (bg != null) {
      final resolvedUrl = nodePlayer.resolvedAssetUrl(bg);
      state = state.copyWith(backgroundImageUrl: () => resolvedUrl);
    } else {
      state = state.copyWith(backgroundImageUrl: () => null);
    }

    // Speaker: set from the current node
    state = state.copyWith(currentSpeaker: () => node.speaker);

    // Characters → activeNpcs (resolve from assetReady, fallback to stateUpdate)
    if (node.characters != null && node.characters!.isNotEmpty) {
      final existingImages = {
        for (final npc in state.activeNpcs)
          if (npc.imageUrl != null) npc.name: npc.imageUrl,
      };
      state = state.copyWith(
        activeNpcs: node.characters!.map((c) {
          // Priority: emotion-specific > default > stateUpdate
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
    } else {
      // characters が null または空 → NPC非表示
      state = state.copyWith(activeNpcs: [], currentSpeaker: () => null);
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

  /// Append multiple GM node messages to the message list.
  void _addGmNodeMessages(List<TrpgMessage> nodeMessages) {
    _messagesNotifier.value = [..._messagesNotifier.value, ...nodeMessages];
  }

  void dispose() {
    _saveTimer?.cancel();
    _cancelSubscriptions();
    _messagesNotifier.dispose();
    _isProcessingNotifier.dispose();
    _visualStateNotifier.dispose();
    _displayModeNotifier.dispose();
    textPager.dispose();
    nodePlayer.dispose();
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
