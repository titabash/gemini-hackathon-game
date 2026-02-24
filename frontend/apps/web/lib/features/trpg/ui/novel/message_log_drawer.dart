import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

import '../../model/trpg_session_provider.dart';

/// Drawer that shows the full conversation history with turn separators.
class MessageLogDrawer extends StatefulWidget {
  const MessageLogDrawer({super.key, required this.messages});

  final List<TrpgMessage> messages;

  @override
  State<MessageLogDrawer> createState() => _MessageLogDrawerState();
}

class _MessageLogDrawerState extends State<MessageLogDrawer> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: Text(t.trpg.messageLog),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      t.trpg.emptyState,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final msg = widget.messages[index];
                      final prevTurn = index > 0
                          ? widget.messages[index - 1].turnNumber
                          : null;
                      final showSeparator =
                          msg.turnNumber != null && msg.turnNumber != prevTurn;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showSeparator)
                            _TurnSeparator(turnNumber: msg.turnNumber!),
                          _LogEntry(message: msg),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TurnSeparator extends StatelessWidget {
  const _TurnSeparator({required this.turnNumber});

  final int turnNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              t.trpg.turnSeparator(n: turnNumber),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  const _LogEntry({required this.message});

  final TrpgMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    // For GM messages with a speaker, show the NPC name
    final label = isUser ? t.trpg.you : message.speaker ?? t.trpg.gm;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(message.text, style: theme.textTheme.bodySmall),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
