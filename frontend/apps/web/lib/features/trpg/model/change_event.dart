/// Events representing visual-feedback-worthy state changes in a TRPG session.
///
/// Emitted by [TrpgSessionNotifier] when a `stateUpdate` SSE event is applied
/// and consumed by [ActionResultOverlayWidget] for animation display.
sealed class ChangeEvent {
  const ChangeEvent();
}

/// A numeric stat changed (e.g. HP, SAN, STR).
class StatChangeEvent extends ChangeEvent {
  const StatChangeEvent({
    required this.statKey,
    required this.delta,
    required this.newValue,
    this.maxValue,
  });

  final String statKey;

  /// Positive = increase, negative = decrease.
  final int delta;
  final int newValue;
  final int? maxValue;
}

/// A new item was added to the player's inventory.
class ItemAcquiredEvent extends ChangeEvent {
  const ItemAcquiredEvent({
    required this.itemName,
    this.description = '',
    this.quantity = 1,
  });

  final String itemName;
  final String description;
  final int quantity;
}

/// An item was removed from the player's inventory.
class ItemRemovedEvent extends ChangeEvent {
  const ItemRemovedEvent({required this.itemName});

  final String itemName;
}

/// A status effect was applied to the player.
class StatusEffectAddedEvent extends ChangeEvent {
  const StatusEffectAddedEvent({required this.effectName});

  final String effectName;
}

/// A status effect was removed from the player.
class StatusEffectRemovedEvent extends ChangeEvent {
  const StatusEffectRemovedEvent({required this.effectName});

  final String effectName;
}

/// The player moved to a new location.
class LocationChangedEvent extends ChangeEvent {
  const LocationChangedEvent({required this.locationName});

  final String locationName;
}

/// An objective was added or updated.
class ObjectiveUpdatedEvent extends ChangeEvent {
  const ObjectiveUpdatedEvent({required this.title, required this.status});

  final String title;

  /// One of: "active", "completed", "failed".
  final String status;
}

/// A relationship with an NPC changed.
class RelationshipChangedEvent extends ChangeEvent {
  const RelationshipChangedEvent({
    required this.npcName,
    this.affinityDelta = 0,
    this.trustDelta = 0,
    this.fearDelta = 0,
    this.debtDelta = 0,
  });

  final String npcName;
  final int affinityDelta;
  final int trustDelta;
  final int fearDelta;
  final int debtDelta;
}
