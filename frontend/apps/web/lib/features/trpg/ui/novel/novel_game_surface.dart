import 'dart:math';

import 'package:core_game/core_game.dart';
import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../api/gm_api.dart';
import '../../model/trpg_session_provider.dart';
import '../../model/trpg_visual_state.dart';
import '../choice_group_widget.dart';
import '../clarify_question_widget.dart';
import '../continue_button_widget.dart';
import '../repair_confirm_widget.dart';
import '../roll_panel_widget.dart';
import 'hud_overlay_widget.dart';
import 'message_log_drawer.dart';
import 'novel_text_box.dart';

/// Full-screen novel-game surface combining Flame background, HUD overlay,
/// and bottom text box / surface / input area.
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
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage({String inputType = 'do', String? overrideText}) {
    final text = overrideText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    final session = ref.read(trpgSessionProvider);
    session.sendTurn(
      sessionId: widget.sessionId,
      inputType: inputType,
      inputText: text,
    );
    _inputController.clear();
  }

  void _onAdvance() {
    final session = ref.read(trpgSessionProvider);
    final advanced = session.textPager.advance();
    if (!advanced) {
      session.onPagingComplete();
    }
  }

  Widget _buildSurface(GmSurfaceUpdateEvent surface) {
    final surfaceWidget = switch (surface.component) {
      'choiceGroup' => ChoiceGroupWidget(
        data: surface.data,
        onChoice: (id, text) =>
            _sendMessage(inputType: 'choice', overrideText: text),
        onFreeInput: (text) => _sendMessage(overrideText: text),
      ),
      'rollPanel' => RollPanelWidget(
        data: surface.data,
        onRoll: () {
          final result = Random().nextInt(20) + 1;
          _sendMessage(
            inputType: 'roll_result',
            overrideText: result.toString(),
          );
        },
      ),
      'clarifyQuestion' => ClarifyQuestionWidget(
        data: surface.data,
        onAnswer: (answer) =>
            _sendMessage(inputType: 'clarify_answer', overrideText: answer),
      ),
      'repairConfirm' => RepairConfirmWidget(
        data: surface.data,
        onAccept: () =>
            _sendMessage(inputType: 'clarify_answer', overrideText: 'accept'),
        onReject: () =>
            _sendMessage(inputType: 'clarify_answer', overrideText: 'reject'),
      ),
      'continueButton' => ContinueButtonWidget(
        onContinue: () =>
            _sendMessage(inputType: 'do', overrideText: 'continue'),
      ),
      _ => const SizedBox.shrink(),
    };

    // Wrap in dark theme for readability on dark background
    return Theme(
      data: ThemeData.dark(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xB3000000),
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: surfaceWidget,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xB3000000),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: TextField(
        controller: _inputController,
        focusNode: _focusNode,
        onSubmitted: (_) => _sendMessage(),
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
            onPressed: _sendMessage,
          ),
        ),
      ),
    );
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

            // Layer 2: HUD overlay (top)
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

            // Layer 3: Bottom area (text box / surface / input)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<NovelDisplayMode>(
                valueListenable: session.displayMode,
                builder: (context, mode, _) {
                  return switch (mode) {
                    NovelDisplayMode.paging => _buildPagingBox(session),
                    NovelDisplayMode.surface => _buildSurfaceArea(session),
                    NovelDisplayMode.input => _buildInputBar(),
                    NovelDisplayMode.processing => _buildProcessingBox(),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagingBox(TrpgSessionNotifier session) {
    return ValueListenableBuilder<String>(
      valueListenable: session.textPager.currentSentence,
      builder: (context, sentence, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: session.textPager.speaker,
          builder: (context, speaker, _) {
            return NovelTextBox(
              text: sentence,
              speaker: speaker,
              showNextIndicator: true,
              onAdvance: _onAdvance,
            );
          },
        );
      },
    );
  }

  Widget _buildSurfaceArea(TrpgSessionNotifier session) {
    return ValueListenableBuilder<GmSurfaceUpdateEvent?>(
      valueListenable: session.currentSurface,
      builder: (context, surface, _) {
        if (surface == null) return _buildInputBar();
        return _buildSurface(surface);
      },
    );
  }

  Widget _buildProcessingBox() {
    return const NovelTextBox(text: '', isProcessing: true, onAdvance: _noop);
  }

  static void _noop() {}
}
