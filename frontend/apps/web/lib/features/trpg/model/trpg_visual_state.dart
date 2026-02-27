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
