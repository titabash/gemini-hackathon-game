import 'package:flutter/material.dart';

/// Novel-game style text box displayed at the bottom of the screen.
///
/// Shows the current speaker name, sentence text, and a pulsing
/// "next" indicator (▼) when there is more text to show.
class VnTextBox extends StatelessWidget {
  const VnTextBox({
    super.key,
    required this.text,
    this.speaker,
    this.showNextIndicator = true,
    this.isProcessing = false,
    required this.onAdvance,
  });

  final String text;
  final String? speaker;
  final bool showNextIndicator;
  final bool isProcessing;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdvance,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xB3000000),
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker name
            if (speaker != null && speaker!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A6A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    speaker!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Text content
            if (isProcessing)
              const VnProcessingIndicator()
            else
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),

            // Next indicator
            if (showNextIndicator && !isProcessing)
              const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: _PulsingTriangle(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing ▼ indicator for "tap to continue".
class _PulsingTriangle extends StatefulWidget {
  const _PulsingTriangle();

  @override
  State<_PulsingTriangle> createState() => _PulsingTriangleState();
}

class _PulsingTriangleState extends State<_PulsingTriangle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Text(
        '▼',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}

/// Processing indicator for VN text box.
class VnProcessingIndicator extends StatelessWidget {
  const VnProcessingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
        SizedBox(width: 8),
        Text('...', style: TextStyle(color: Colors.white54, fontSize: 15)),
      ],
    );
  }
}
