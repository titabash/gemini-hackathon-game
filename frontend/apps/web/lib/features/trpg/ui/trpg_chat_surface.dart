import 'dart:math';

import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api/gm_api.dart';
import '../model/trpg_session_provider.dart';
import 'choice_group_widget.dart';
import 'clarify_question_widget.dart';
import 'continue_button_widget.dart';
import 'repair_confirm_widget.dart';
import 'roll_panel_widget.dart';

/// TRPG chat surface with typewriter text streaming and interactive GM surfaces.
class TrpgChatSurface extends ConsumerStatefulWidget {
  const TrpgChatSurface({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<TrpgChatSurface> createState() => _TrpgChatSurfaceState();
}

class _TrpgChatSurfaceState extends ConsumerState<TrpgChatSurface> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({String inputType = 'do', String? overrideText}) {
    final text = overrideText ?? _controller.text.trim();
    if (text.isEmpty) return;

    final session = ref.read(trpgSessionProvider);
    session.sendTurn(
      sessionId: widget.sessionId,
      inputType: inputType,
      inputText: text,
    );
    _controller.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildSurface(GmSurfaceUpdateEvent surface) {
    return switch (surface.component) {
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
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(trpgSessionProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Message list
        Expanded(
          child: ValueListenableBuilder<List<TrpgMessage>>(
            valueListenable: session.messages,
            builder: (context, messages, _) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    t.trpg.emptyState,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return _MessageBubble(message: msg);
                },
              );
            },
          ),
        ),

        // Surface area (choices, roll panel, etc.)
        ValueListenableBuilder<GmSurfaceUpdateEvent?>(
          valueListenable: session.currentSurface,
          builder: (context, surface, _) {
            if (surface == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSurface(surface),
            );
          },
        ),

        // Processing indicator
        ValueListenableBuilder<bool>(
          valueListenable: session.isProcessing,
          builder: (context, isProcessing, _) {
            if (!isProcessing) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(t.trpg.processing, style: theme.textTheme.bodySmall),
                ],
              ),
            );
          },
        ),

        // Input bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: t.trpg.inputHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TrpgMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
