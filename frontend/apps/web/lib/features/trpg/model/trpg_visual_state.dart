/// Visual state for the Flame TRPG game canvas.
///
/// Updated by [TrpgSessionNotifier] when GM sends stateUpdate events.
class TrpgVisualState {
  const TrpgVisualState({
    this.locationName,
    this.sceneDescription,
    this.activeNpcs = const [],
    this.currentSpeaker,
    this.hp = 100,
    this.maxHp = 100,
    this.playerName = 'Player',
    this.backgroundImageUrl,
    this.bgmMood,
    this.stats = const {},
    this.maxStats = const {},
    this.statusEffects = const [],
    this.items = const [],
    this.objectives = const [],
    this.relationships = const [],
  });

  final String? locationName;
  final String? sceneDescription;
  final List<NpcVisual> activeNpcs;

  /// Name of the NPC currently speaking (used for highlight/dim).
  final String? currentSpeaker;
  final int hp;
  final int maxHp;
  final String playerName;
  final String? backgroundImageUrl;
  final String? bgmMood;

  /// All character stats (e.g. hp, san, str). Values are current amounts.
  final Map<String, int> stats;

  /// Maximum values for stats that have caps (e.g. max_hp, max_san).
  final Map<String, int> maxStats;

  /// Active status effects (e.g. "poisoned", "blinded").
  final List<String> statusEffects;

  /// Player inventory items.
  final List<InventoryItem> items;

  /// Current objectives/quests.
  final List<ObjectiveInfo> objectives;

  /// NPC relationship values.
  final List<NpcRelationship> relationships;

  TrpgVisualState copyWith({
    String? locationName,
    String? sceneDescription,
    List<NpcVisual>? activeNpcs,
    String? Function()? currentSpeaker,
    int? hp,
    int? maxHp,
    String? playerName,
    String? Function()? backgroundImageUrl,
    String? Function()? bgmMood,
    Map<String, int>? stats,
    Map<String, int>? maxStats,
    List<String>? statusEffects,
    List<InventoryItem>? items,
    List<ObjectiveInfo>? objectives,
    List<NpcRelationship>? relationships,
  }) {
    return TrpgVisualState(
      locationName: locationName ?? this.locationName,
      sceneDescription: sceneDescription ?? this.sceneDescription,
      activeNpcs: activeNpcs ?? this.activeNpcs,
      currentSpeaker: currentSpeaker != null
          ? currentSpeaker()
          : this.currentSpeaker,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      playerName: playerName ?? this.playerName,
      backgroundImageUrl: backgroundImageUrl != null
          ? backgroundImageUrl()
          : this.backgroundImageUrl,
      bgmMood: bgmMood != null ? bgmMood() : this.bgmMood,
      stats: stats ?? this.stats,
      maxStats: maxStats ?? this.maxStats,
      statusEffects: statusEffects ?? this.statusEffects,
      items: items ?? this.items,
      objectives: objectives ?? this.objectives,
      relationships: relationships ?? this.relationships,
    );
  }
}

/// Visual representation of an NPC on the game canvas.
class NpcVisual {
  const NpcVisual({required this.name, this.emotion, this.imageUrl});

  final String name;
  final String? emotion;

  /// Resolved public URL for the NPC portrait image.
  final String? imageUrl;
}

/// A single item in the player's inventory.
class InventoryItem {
  const InventoryItem({
    required this.name,
    this.description = '',
    this.itemType = '',
    this.quantity = 1,
    this.isEquipped = false,
  });

  final String name;
  final String description;
  final String itemType;
  final int quantity;
  final bool isEquipped;

  InventoryItem copyWith({
    String? name,
    String? description,
    String? itemType,
    int? quantity,
    bool? isEquipped,
  }) {
    return InventoryItem(
      name: name ?? this.name,
      description: description ?? this.description,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }
}

/// An objective/quest with status tracking.
class ObjectiveInfo {
  const ObjectiveInfo({
    required this.title,
    required this.status,
    this.description,
  });

  final String title;

  /// One of: "active", "completed", "failed".
  final String status;
  final String? description;

  ObjectiveInfo copyWith({String? title, String? status, String? description}) {
    return ObjectiveInfo(
      title: title ?? this.title,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }
}

/// Relationship values with an NPC.
class NpcRelationship {
  const NpcRelationship({
    required this.npcName,
    this.affinity = 0,
    this.trust = 0,
    this.fear = 0,
    this.debt = 0,
  });

  final String npcName;
  final int affinity;
  final int trust;
  final int fear;
  final int debt;

  NpcRelationship copyWith({
    String? npcName,
    int? affinity,
    int? trust,
    int? fear,
    int? debt,
  }) {
    return NpcRelationship(
      npcName: npcName ?? this.npcName,
      affinity: affinity ?? this.affinity,
      trust: trust ?? this.trust,
      fear: fear ?? this.fear,
      debt: debt ?? this.debt,
    );
  }
}
