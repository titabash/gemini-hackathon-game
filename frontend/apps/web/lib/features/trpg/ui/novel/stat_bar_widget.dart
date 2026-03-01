import 'package:flutter/material.dart';

/// A single stat bar with label, value, and optional max-value progress bar.
///
/// Flashes green on value increase and red on value decrease.
class StatBarWidget extends StatefulWidget {
  const StatBarWidget({
    super.key,
    required this.label,
    required this.value,
    this.maxValue,
  });

  final String label;
  final int value;
  final int? maxValue;

  @override
  State<StatBarWidget> createState() => _StatBarWidgetState();
}

class _StatBarWidgetState extends State<StatBarWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _flashController;
  Color _flashColor = Colors.transparent;

  @override
  void didUpdateWidget(StatBarWidget oldWidget) {
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
    final hasMax = widget.maxValue != null && widget.maxValue! > 0;
    final ratio = hasMax
        ? (widget.value / widget.maxValue!).clamp(0.0, 1.0)
        : 0.0;
    final color = ratio > 0.5
        ? const Color(0xFF44CC44)
        : ratio > 0.25
        ? const Color(0xFFCCAA22)
        : const Color(0xFFCC4444);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              widget.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          if (hasMax) ...[
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: ratio),
                duration: const Duration(milliseconds: 300),
                builder: (context, animatedRatio, _) {
                  return SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: animatedRatio,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                        if (_flashController != null)
                          AnimatedBuilder(
                            animation: _flashController!,
                            builder: (context, _) {
                              final opacity =
                                  (1.0 - _flashController!.value) * 0.5;
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
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.value}/${widget.maxValue}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ] else
            Text(
              '${widget.value}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
        ],
      ),
    );
  }
}
