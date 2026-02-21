import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

/// Renders a dice roll check panel.
class RollPanelWidget extends StatelessWidget {
  const RollPanelWidget({super.key, required this.data, required this.onRoll});

  final Map<String, dynamic> data;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final skillName = data['skill_name'] as String? ?? '';
    final difficulty = data['difficulty'] as int? ?? 0;
    final stakesSuccess = data['stakes_success'] as String? ?? '';
    final stakesFailure = data['stakes_failure'] as String? ?? '';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.casino, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${t.trpg.rollCheck}: $skillName',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(t.trpg.rollDifficulty(n: difficulty)),
            const SizedBox(height: 4),
            Text(
              t.trpg.rollSuccess(text: stakesSuccess),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              t.trpg.rollFailure(text: stakesFailure),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRoll,
              icon: const Icon(Icons.casino),
              label: Text(t.trpg.rollButton),
            ),
          ],
        ),
      ),
    );
  }
}
