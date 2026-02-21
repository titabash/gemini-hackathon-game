/// Visual state for the Flame TRPG game canvas.
///
/// Updated by [TrpgSessionNotifier] when GM sends stateUpdate events.
class TrpgVisualState {
  const TrpgVisualState({
    this.locationName,
    this.sceneDescription,
    this.activeNpcs = const [],
    this.hp = 100,
    this.maxHp = 100,
    this.playerName = 'Player',
    this.backgroundImageUrl,
  });

  final String? locationName;
  final String? sceneDescription;
  final List<NpcVisual> activeNpcs;
  final int hp;
  final int maxHp;
  final String playerName;
  final String? backgroundImageUrl;

  TrpgVisualState copyWith({
    String? locationName,
    String? sceneDescription,
    List<NpcVisual>? activeNpcs,
    int? hp,
    int? maxHp,
    String? playerName,
    String? backgroundImageUrl,
  }) {
    return TrpgVisualState(
      locationName: locationName ?? this.locationName,
      sceneDescription: sceneDescription ?? this.sceneDescription,
      activeNpcs: activeNpcs ?? this.activeNpcs,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      playerName: playerName ?? this.playerName,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
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
