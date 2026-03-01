import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

/// Horizontal list of status effect pill badges.
class StatusEffectsWidget extends StatelessWidget {
  const StatusEffectsWidget({super.key, required this.effects});

  final List<String> effects;

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.trpg.statusEffects,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: effects.map((effect) {
            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x66CC4444),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xAACC4444),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  effect,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
