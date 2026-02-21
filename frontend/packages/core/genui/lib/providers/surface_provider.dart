import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'conversation_provider.dart';

/// Tracks active surface IDs from the genui conversation.
///
/// Listens to [GenUiUpdate] events from the [A2uiMessageProcessor] and
/// maintains a list of active surface IDs.
///
/// Uses a manual Provider because genui event types are not compatible
/// with riverpod_generator.
final surfaceIdsProvider = Provider<ValueNotifier<List<String>>>((ref) {
  final conversation = ref.watch(genuiConversationProvider);
  final notifier = ValueNotifier<List<String>>([]);

  final subscription = conversation.host.surfaceUpdates.listen((update) {
    switch (update) {
      case SurfaceAdded():
        notifier.value = [...notifier.value, update.surfaceId];
      case SurfaceRemoved():
        notifier.value = notifier.value
            .where((id) => id != update.surfaceId)
            .toList();
      case SurfaceUpdated():
        break;
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    notifier.dispose();
  });

  return notifier;
});
