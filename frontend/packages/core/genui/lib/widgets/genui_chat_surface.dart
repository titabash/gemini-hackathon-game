import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/conversation_provider.dart';
import '../providers/surface_provider.dart';
import 'genui_surface_view.dart';

/// A chat UI that combines a [GenuiSurfaceView] list with a text input field.
///
/// Displays all active surfaces from the genui conversation and provides
/// a text field for the user to send messages.
class GenuiChatSurface extends ConsumerStatefulWidget {
  const GenuiChatSurface({super.key});

  @override
  ConsumerState<GenuiChatSurface> createState() => _GenuiChatSurfaceState();
}

class _GenuiChatSurfaceState extends ConsumerState<GenuiChatSurface> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final conversation = ref.read(genuiConversationProvider);
    conversation.sendRequest(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceIdsNotifier = ref.watch(surfaceIdsProvider);
    final conversation = ref.watch(genuiConversationProvider);

    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: surfaceIdsNotifier,
            builder: (context, surfaceIds, _) {
              if (surfaceIds.isEmpty) {
                return const Center(child: Text('Start a conversation'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: surfaceIds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GenuiSurfaceView(
                      processor: conversation.processor,
                      surfaceId: surfaceIds[index],
                    ),
                  );
                },
              );
            },
          ),
        ),
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
                    hintText: 'Type a message...',
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
