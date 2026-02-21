import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

/// Renders a contradiction repair confirmation panel.
class RepairConfirmWidget extends StatelessWidget {
  const RepairConfirmWidget({
    super.key,
    required this.data,
    required this.onAccept,
    required this.onReject,
  });

  final Map<String, dynamic> data;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final contradiction = data['contradiction'] as String? ?? '';
    final proposedFix = data['proposed_fix'] as String? ?? '';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, size: 20),
                const SizedBox(width: 8),
                Text(t.trpg.repairTitle, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t.trpg.repairContradiction(text: contradiction),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              t.trpg.repairFix(text: proposedFix),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onReject,
                  child: Text(t.trpg.repairReject),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAccept,
                  child: Text(t.trpg.repairAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
