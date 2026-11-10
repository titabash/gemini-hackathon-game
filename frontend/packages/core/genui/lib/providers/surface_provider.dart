import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'conversation_provider.dart';

/// Tracks active surface IDs from the genui conversation.
///
/// Listens to the surface events of the conversation's A2UI processor and
/// maintains a list of active surface IDs.
///
/// Uses a manual Provider because the A2UI event types are not compatible
/// with riverpod_generator.
final surfaceIdsProvider = Provider<ValueNotifier<List<String>>>((ref) {
  final conversation = ref.watch(genuiConversationProvider);
  final model = conversation.processor.model;
  final notifier = ValueNotifier<List<String>>([]);

  final created = model.onSurfaceCreated.subscribe((surface) {
    notifier.value = [...notifier.value, surface.id];
  });
  final deleted = model.onSurfaceDeleted.subscribe((surfaceId) {
    notifier.value = notifier.value.where((id) => id != surfaceId).toList();
  });

  ref.onDispose(() {
    created.unsubscribe();
    deleted.unsubscribe();
    notifier.dispose();
  });

  return notifier;
});
