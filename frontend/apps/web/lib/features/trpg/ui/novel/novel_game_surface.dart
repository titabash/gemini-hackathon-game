import 'package:core_game/core_game.dart';
import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_ui/vn/vn.dart';

import '../../model/trpg_session_provider.dart';
import '../../model/trpg_visual_state.dart';
import 'hud_overlay_widget.dart';
import 'message_log_drawer.dart';

/// Full-screen novel-game surface combining Flame background, genui surfaces,
/// HUD overlay, and bottom text box / input area.
class NovelGameSurface extends ConsumerStatefulWidget {
  const NovelGameSurface({
    super.key,
    required this.sessionId,
    required this.game,
  });

  final String sessionId;
  final BaseGame game;

  @override
  ConsumerState<NovelGameSurface> createState() => _NovelGameSurfaceState();
}

class _NovelGameSurfaceState extends ConsumerState<NovelGameSurface> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _sendMessage({String inputType = 'do', String? overrideText}) {
    final text = overrideText ?? '';
    if (text.isEmpty) return;

    final session = ref.read(trpgSessionProvider);
    session.sendTurn(
      sessionId: widget.sessionId,
      inputType: inputType,
      inputText: text,
    );
  }

  void _onAdvance() {
    final session = ref.read(trpgSessionProvider);
    final advanced = session.textPager.advance();
    if (!advanced) {
      session.onPagingComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(trpgSessionProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: ValueListenableBuilder<List<TrpgMessage>>(
        valueListenable: session.messages,
        builder: (context, msgs, _) {
          return MessageLogDrawer(messages: msgs);
        },
      ),
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            final mode = session.displayMode.value;
            if (mode == NovelDisplayMode.paging) {
              if (event.logicalKey == LogicalKeyboardKey.space ||
                  event.logicalKey == LogicalKeyboardKey.enter) {
                _onAdvance();
              }
            }
          }
        },
        child: Stack(
          children: [
            // Layer 1: Flame game (full screen)
            Positioned.fill(child: GameContainer(game: widget.game)),

            // Layer 2: NPC gallery (full-height, bottom-aligned)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 80,
              child: GenUiSurface(
                host: session.processor,
                surfaceId: 'game-npcs',
              ),
            ),

            // Layer 3: Bottom area (mode-dependent)
            ValueListenableBuilder<NovelDisplayMode>(
              valueListenable: session.displayMode,
              builder: (context, mode, _) {
                return switch (mode) {
                  NovelDisplayMode.paging => _buildPagingOverlay(session),
                  NovelDisplayMode.surface => _buildSurfaceOverlay(session),
                  NovelDisplayMode.input => _buildInputOverlay(session),
                  NovelDisplayMode.processing => _buildProcessingOverlay(),
                };
              },
            ),

            // Layer 4: HUD overlay (top, always visible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<TrpgVisualState>(
                valueListenable: session.visualState,
                builder: (context, vs, _) {
                  return HudOverlayWidget(
                    visualState: vs,
                    onMessageLogTap: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Paging mode: sentence-by-sentence text display at bottom.
  Widget _buildPagingOverlay(TrpgSessionNotifier session) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<String>(
        valueListenable: session.textPager.currentSentence,
        builder: (context, sentence, _) {
          return ValueListenableBuilder<String?>(
            valueListenable: session.textPager.speaker,
            builder: (context, speaker, _) {
              return VnTextBox(
                text: sentence,
                speaker: speaker,
                showNextIndicator: true,
                onAdvance: _onAdvance,
              );
            },
          );
        },
      ),
    );
  }

  /// Surface mode: genui surface (choices/roll/etc.) + narration context.
  /// Uses full-screen layout with Spacer to push content to the bottom.
  Widget _buildSurfaceOverlay(TrpgSessionNotifier session) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          // genui surface (choices, roll panel, etc.)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GenUiSurface(
              host: session.processor,
              surfaceId: 'game-surface',
              defaultBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 8),
          // Narration at bottom
          GenUiSurface(
            host: session.processor,
            surfaceId: 'game-narration',
            defaultBuilder: (_) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Input mode: genui textInput surface or fallback input bar.
  Widget _buildInputOverlay(TrpgSessionNotifier session) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GenUiSurface(
        host: session.processor,
        surfaceId: 'game-surface',
        defaultBuilder: (_) => _FallbackInputBar(onSend: _sendMessage),
      ),
    );
  }

  /// Processing mode: processing indicator at bottom.
  Widget _buildProcessingOverlay() {
    return const Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: VnTextBox(text: '', isProcessing: true, onAdvance: _noop),
    );
  }

  static void _noop() {}
}

/// Fallback text input bar when no genui surface is available.
class _FallbackInputBar extends StatefulWidget {
  const _FallbackInputBar({required this.onSend});

  final void Function({String inputType, String? overrideText}) onSend;

  @override
  State<_FallbackInputBar> createState() => _FallbackInputBarState();
}

class _FallbackInputBarState extends State<_FallbackInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(overrideText: text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return VnOverlayContainer(
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _submit(),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          hintText: t.trpg.inputHint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white10,
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Colors.white54),
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}
