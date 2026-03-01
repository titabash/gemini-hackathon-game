import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';

/// NPC relationship panel showing non-zero affinity/trust/fear/debt values.
class RelationshipsPanelWidget extends StatelessWidget {
  const RelationshipsPanelWidget({super.key, required this.relationships});

  final List<NpcRelationship> relationships;

  @override
  Widget build(BuildContext context) {
    if (relationships.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: relationships.map((rel) {
        final values = <(String, int, Color)>[
          if (rel.affinity != 0)
            (t.trpg.affinity, rel.affinity, const Color(0xFFFF88AA)),
          if (rel.trust != 0)
            (t.trpg.trust, rel.trust, const Color(0xFF88CCFF)),
          if (rel.fear != 0) (t.trpg.fear, rel.fear, const Color(0xFFCC88FF)),
          if (rel.debt != 0) (t.trpg.debt, rel.debt, const Color(0xFFFFCC44)),
        ];

        if (values.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rel.npcName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: values.map((v) {
                  final (label, value, color) = v;
                  final sign = value > 0 ? '+' : '';
                  return Text(
                    '$label: $sign$value',
                    style: TextStyle(color: color, fontSize: 10),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
