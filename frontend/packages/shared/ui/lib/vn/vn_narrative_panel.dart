import 'package:flutter/material.dart';

/// A single section within a narrative panel.
///
/// [type] is either `"dialogue"` (NPC speech with speaker badge) or
/// `"narration"` (narrator text without badge).
class VnNarrativeSection {
  const VnNarrativeSection({
    required this.type,
    this.speaker,
    required this.text,
  });

  /// `"dialogue"` or `"narration"`.
  final String type;

  /// Speaker name shown as a badge. Only used when [type] is `"dialogue"`.
  final String? speaker;

  /// The text content to display.
  final String text;
}

/// VN-style narrative panel that renders structured dialogue/narration sections.
///
/// Each section is rendered differently:
/// - **dialogue**: Speaker badge (coloured chip) + speech text
/// - **narration**: Plain text without badge, slightly different style
///
/// Tapping anywhere calls [onAdvance] (used for paging / "next").
class VnNarrativePanel extends StatelessWidget {
  const VnNarrativePanel({
    super.key,
    required this.sections,
    required this.onAdvance,
    this.showNextIndicator = true,
  });

  final List<VnNarrativeSection> sections;
  final VoidCallback onAdvance;
  final bool showNextIndicator;

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
            for (final section in sections)
              if (section.type == 'dialogue')
                _DialogueSection(section: section)
              else
                _NarrationSection(section: section),
            if (showNextIndicator)
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

class _DialogueSection extends StatelessWidget {
  const _DialogueSection({required this.section});

  final VnNarrativeSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (section.speaker != null && section.speaker!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
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
                  section.speaker!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Text(
            section.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrationSection extends StatelessWidget {
  const _NarrationSection({required this.section});

  final VnNarrativeSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        section.text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// Pulsing triangle indicator for "tap to continue".
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
        '\u25bc',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}
