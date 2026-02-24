/// Character display specification for a scene node.
class CharacterDisplay {
  const CharacterDisplay({
    required this.npcName,
    this.expression,
    this.position = 'center',
  });

  /// Parse from a JSON map (SSE payload).
  factory CharacterDisplay.fromJson(Map<String, dynamic> json) {
    return CharacterDisplay(
      npcName: json['npc_name'] as String? ?? '',
      expression: json['expression'] as String?,
      position: json['position'] as String? ?? 'center',
    );
  }

  /// NPC name matching the backend NPC registry.
  final String npcName;

  /// Facial expression: joy, anger, sadness, pleasure, surprise, or null.
  final String? expression;

  /// Screen position: left, center, right.
  final String position;
}

/// A single visual novel page with complete visual state.
class SceneNode {
  const SceneNode({
    required this.type,
    required this.text,
    this.speaker,
    this.background,
    this.characters,
    this.choices,
    this.cg,
    this.cgClear = false,
    this.bgm,
    this.bgmStop = false,
    this.se,
    this.voiceId,
  });

  /// Parse from a JSON map (SSE payload).
  factory SceneNode.fromJson(Map<String, dynamic> json) {
    return SceneNode(
      type: json['type'] as String? ?? 'narration',
      text: json['text'] as String? ?? '',
      speaker: json['speaker'] as String?,
      background: json['background'] as String?,
      characters: (json['characters'] as List<dynamic>?)
          ?.map((e) => CharacterDisplay.fromJson(e as Map<String, dynamic>))
          .toList(),
      choices: (json['choices'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>()
          .toList(),
      cg: json['cg'] as String?,
      cgClear: json['cg_clear'] as bool? ?? false,
      bgm: json['bgm'] as String?,
      bgmStop: json['bgm_stop'] as bool? ?? false,
      se: json['se'] as String?,
      voiceId: json['voice_id'] as String?,
    );
  }

  /// Node type: narration, dialogue, or choice.
  final String type;

  /// Text content for this page.
  final String text;

  /// Speaker NPC name (dialogue nodes only).
  final String? speaker;

  /// Background ID or generation description.
  final String? background;

  /// Characters visible on screen.
  final List<CharacterDisplay>? characters;

  /// Choice options (choice nodes only). Raw JSON maps.
  final List<Map<String, dynamic>>? choices;

  // -- Future extension fields (processing not yet implemented) --

  /// CG image instruction.
  final String? cg;

  /// Whether to clear the CG overlay.
  final bool cgClear;

  /// BGM instruction.
  final String? bgm;

  /// Whether to stop BGM.
  final bool bgmStop;

  /// Sound effect instruction.
  final String? se;

  /// Voice ID.
  final String? voiceId;
}
