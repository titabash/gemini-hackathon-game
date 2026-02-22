import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';

/// NPC gallery data for a single character.
class VnNpcData {
  const VnNpcData({required this.name, this.emotion, this.imagePath});

  final String name;
  final String? emotion;
  final String? imagePath;
}

/// VN-style NPC standing portrait gallery.
///
/// Displays large NPC portraits that fill most of the available height,
/// aligned from the bottom edge.  Speaking NPCs (those whose name appears
/// in [speakers]) are rendered at full brightness and placed in front;
/// non-speaking NPCs are dimmed with a dark colour filter.
class VnNpcGallery extends StatelessWidget {
  const VnNpcGallery({super.key, required this.npcs, this.speakers = const []});

  final List<VnNpcData> npcs;

  /// Names of the NPCs currently speaking.  Used to highlight the active
  /// speaker and dim everyone else.
  final List<String> speakers;

  @override
  Widget build(BuildContext context) {
    if (npcs.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final npcHeight = height * 0.75;
        final ordered = _zOrderedNpcs();
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: ordered
              .map(
                (npc) => _buildPositionedNpc(
                  npc,
                  npcs.indexOf(npc),
                  width,
                  npcHeight,
                ),
              )
              .toList(),
        );
      },
    );
  }

  /// Reorder NPCs so speakers are rendered last (on top in the [Stack]).
  List<VnNpcData> _zOrderedNpcs() {
    final nonSpeakers = <VnNpcData>[];
    final speakerNpcs = <VnNpcData>[];
    for (final npc in npcs) {
      if (speakers.contains(npc.name)) {
        speakerNpcs.add(npc);
      } else {
        nonSpeakers.add(npc);
      }
    }
    return [...nonSpeakers, ...speakerNpcs];
  }

  Widget _buildPositionedNpc(
    VnNpcData npc,
    int origIndex,
    double totalWidth,
    double npcHeight,
  ) {
    final isSpeaking = speakers.contains(npc.name);
    final count = npcs.length;

    // Evenly distribute centres with slight overlap allowed.
    final spacing = totalWidth / (count + 1);
    final centerX = spacing * (origIndex + 1);
    final npcWidth = (totalWidth / count).clamp(120.0, 300.0);

    Widget child = _buildNpc(npc, npcHeight);

    // Dim non-speaking NPCs.
    if (!isSpeaking && speakers.isNotEmpty) {
      child = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.35, 0, 0, 0, 0, //
          0, 0.35, 0, 0, 0,
          0, 0, 0.35, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }

    return Positioned(
      left: centerX - npcWidth / 2,
      bottom: isSpeaking ? 8 : 0,
      width: npcWidth,
      child: child,
    );
  }

  Widget _buildNpc(VnNpcData npc, double npcHeight) {
    return SizedBox(
      height: npcHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Portrait (bottom-aligned, fills available height)
          Positioned.fill(
            child: npc.imagePath != null && npc.imagePath!.isNotEmpty
                ? Image.network(
                    npc.imagePath!,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, error, _) {
                      Logger.error(
                        'NpcGallery image load failed: '
                        'url=${npc.imagePath}, name=${npc.name}',
                        error,
                      );
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildFallback(npc),
                      );
                    },
                  )
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildFallback(npc),
                  ),
          ),

          // Name plate + emotion overlaid at bottom of portrait
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB3000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    npc.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (npc.emotion != null && npc.emotion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      npc.emotion!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback(VnNpcData npc) {
    final initial = npc.name.isNotEmpty ? npc.name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 48,
      backgroundColor: const Color(0xFFCC6644),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
