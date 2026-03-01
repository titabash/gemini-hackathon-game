import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';

/// Objective list with status-based color coding.
class ObjectivesPanelWidget extends StatelessWidget {
  const ObjectivesPanelWidget({super.key, required this.objectives});

  final List<ObjectiveInfo> objectives;

  @override
  Widget build(BuildContext context) {
    if (objectives.isEmpty) {
      return Text(
        t.trpg.noObjectives,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: objectives.map((obj) {
        final (icon, color, label) = _statusVisual(obj.status);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  obj.title,
                  style: TextStyle(
                    color: obj.status == 'completed'
                        ? Colors.white38
                        : Colors.white,
                    fontSize: 11,
                    decoration: obj.status == 'completed'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(label, style: TextStyle(color: color, fontSize: 9)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static (IconData, Color, String) _statusVisual(String status) {
    return switch (status) {
      'completed' => (
        Icons.check_circle,
        const Color(0xFF44CC44),
        t.trpg.objectiveCompleted,
      ),
      'failed' => (
        Icons.cancel,
        const Color(0xFFCC4444),
        t.trpg.objectiveFailed,
      ),
      _ => (
        Icons.radio_button_unchecked,
        const Color(0xFFCCAA22),
        t.trpg.objectiveActive,
      ),
    };
  }
}
