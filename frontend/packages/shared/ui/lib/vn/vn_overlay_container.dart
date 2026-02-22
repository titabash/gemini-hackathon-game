import 'package:flutter/material.dart';

/// Semi-transparent dark overlay container for VN-style UI elements.
class VnOverlayContainer extends StatelessWidget {
  const VnOverlayContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        color: Color(0xB3000000),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Theme(data: ThemeData.dark(), child: child),
    );
  }
}
