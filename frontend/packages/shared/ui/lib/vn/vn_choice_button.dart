import 'package:flutter/material.dart';

/// VN-style choice button with semi-transparent dark background.
///
/// Uses [GestureDetector] with [HitTestBehavior.opaque] instead of
/// [InkWell] for reliable tap detection on Flutter Web (CanvasKit).
class VnChoiceButton extends StatefulWidget {
  const VnChoiceButton({
    super.key,
    required this.text,
    this.hint,
    required this.onPressed,
  });

  final String text;
  final String? hint;
  final VoidCallback onPressed;

  @override
  State<VnChoiceButton> createState() => _VnChoiceButtonState();
}

class _VnChoiceButtonState extends State<VnChoiceButton> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed ? const Color(0x99000000) : const Color(0x66000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _pressed ? Colors.white54 : Colors.white24,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              if (widget.hint != null && widget.hint!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.hint!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
