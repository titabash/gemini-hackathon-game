import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';

/// HUD overlay showing HP bar and location name on top of the game canvas.
class HudOverlayWidget extends StatelessWidget {
  const HudOverlayWidget({
    super.key,
    required this.visualState,
    required this.bgmPlaying,
    required this.bgmMuted,
    required this.bgmGenerating,
    this.onBgmToggle,
    this.onMessageLogTap,
  });

  final TrpgVisualState visualState;
  final bool bgmPlaying;
  final bool bgmMuted;
  final bool bgmGenerating;
  final VoidCallback? onBgmToggle;
  final VoidCallback? onMessageLogTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HP bar (left)
            _HpBarWidget(hp: visualState.hp, maxHp: visualState.maxHp),
            const Spacer(),
            // Location badge + message log button (right)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (visualState.locationName != null &&
                    visualState.locationName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          visualState.locationName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (onMessageLogTap != null) ...[
                  const SizedBox(height: 8),
                  _CircleButton(
                    icon: Icons.history,
                    tooltip: t.trpg.messageLog,
                    onTap: onMessageLogTap!,
                  ),
                ],
                if (onBgmToggle != null) ...[
                  const SizedBox(height: 8),
                  _CircleButton(
                    icon: !bgmPlaying || bgmMuted
                        ? Icons.music_off
                        : Icons.music_note,
                    tooltip: !bgmPlaying || bgmMuted
                        ? t.trpg.bgmOff
                        : t.trpg.bgmOn,
                    onTap: onBgmToggle!,
                  ),
                ],
                if (bgmGenerating) ...[
                  const SizedBox(height: 6),
                  Text(
                    t.trpg.bgmGenerating,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HpBarWidget extends StatelessWidget {
  const _HpBarWidget({required this.hp, required this.maxHp});

  final int hp;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
    final ratio = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
    final color = ratio > 0.5
        ? const Color(0xFF44CC44)
        : ratio > 0.25
        ? const Color(0xFFCCAA22)
        : const Color(0xFFCC4444);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HP $hp / $maxHp',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 100,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
        ),
      ),
    );
  }
}
