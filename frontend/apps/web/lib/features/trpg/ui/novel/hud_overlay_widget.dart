import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';

/// HUD overlay showing compact stats, location name, and parameter panel
/// toggle on top of the game canvas.
class HudOverlayWidget extends StatelessWidget {
  const HudOverlayWidget({
    super.key,
    required this.visualState,
    required this.bgmPlaying,
    required this.bgmMuted,
    required this.bgmGenerating,
    this.onBgmToggle,
    this.onMessageLogTap,
    this.onParameterPanelToggle,
    this.isParameterPanelOpen = false,
  });

  final TrpgVisualState visualState;
  final bool bgmPlaying;
  final bool bgmMuted;
  final bool bgmGenerating;
  final VoidCallback? onBgmToggle;
  final VoidCallback? onMessageLogTap;
  final VoidCallback? onParameterPanelToggle;
  final bool isParameterPanelOpen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact stats + expand button (left)
            _CompactStatsWidget(
              visualState: visualState,
              isExpanded: isParameterPanelOpen,
              onToggle: onParameterPanelToggle,
            ),
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

/// Compact stats display with expand/collapse toggle for the parameter panel.
class _CompactStatsWidget extends StatelessWidget {
  const _CompactStatsWidget({
    required this.visualState,
    required this.isExpanded,
    this.onToggle,
  });

  final TrpgVisualState visualState;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _buildStatBars(),
          ),
          if (onToggle != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isExpanded ? Icons.chevron_left : Icons.menu,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStatBars() {
    final bars = <Widget>[];

    if (visualState.stats.isNotEmpty) {
      // Show stats that have max values (up to 3)
      var count = 0;
      for (final entry in visualState.stats.entries) {
        if (count >= 3) break;
        final maxKey = 'max_${entry.key}';
        final maxVal = visualState.maxStats[maxKey];
        if (maxVal != null && maxVal > 0) {
          bars.add(
            _MiniStatBar(
              label: entry.key.toUpperCase(),
              value: entry.value,
              maxValue: maxVal,
            ),
          );
          count++;
        }
      }
    }

    // Fallback to legacy HP
    if (bars.isEmpty && visualState.maxHp > 0) {
      bars.add(
        _MiniStatBar(
          label: 'HP',
          value: visualState.hp,
          maxValue: visualState.maxHp,
        ),
      );
    }

    return bars;
  }
}

/// Minimal stat bar for the compact HUD display.
///
/// Flashes green on value increase and red on value decrease.
class _MiniStatBar extends StatefulWidget {
  const _MiniStatBar({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final int value;
  final int? maxValue;

  @override
  State<_MiniStatBar> createState() => _MiniStatBarState();
}

class _MiniStatBarState extends State<_MiniStatBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _flashController;
  Color _flashColor = Colors.transparent;

  @override
  void didUpdateWidget(_MiniStatBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _triggerFlash(widget.value > oldWidget.value);
    }
  }

  @override
  void dispose() {
    _flashController?.dispose();
    super.dispose();
  }

  void _triggerFlash(bool increase) {
    _flashController?.dispose();
    _flashColor = increase ? const Color(0xFF43A047) : const Color(0xFFE53935);
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.maxValue ?? widget.value;
    final ratio = max > 0 ? (widget.value / max).clamp(0.0, 1.0) : 0.0;
    final color = ratio > 0.5
        ? const Color(0xFF44CC44)
        : ratio > 0.25
        ? const Color(0xFFCCAA22)
        : const Color(0xFFCC4444);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.label} ${widget.value} / $max',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 80,
            height: 6,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                if (_flashController != null)
                  AnimatedBuilder(
                    animation: _flashController!,
                    builder: (context, _) {
                      final opacity = (1.0 - _flashController!.value) * 0.5;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: ColoredBox(
                          color: _flashColor.withValues(alpha: opacity),
                          child: const SizedBox.expand(),
                        ),
                      );
                    },
                  ),
              ],
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
