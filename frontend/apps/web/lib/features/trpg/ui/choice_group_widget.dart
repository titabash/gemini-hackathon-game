import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

/// Renders GM choice options for the player.
class ChoiceGroupWidget extends StatelessWidget {
  const ChoiceGroupWidget({
    super.key,
    required this.data,
    required this.onChoice,
    required this.onFreeInput,
  });

  final Map<String, dynamic> data;
  final void Function(String choiceId, String text) onChoice;
  final void Function(String text) onFreeInput;

  @override
  Widget build(BuildContext context) {
    final choices = (data['choices'] as List<dynamic>?) ?? [];
    final allowFreeInput = (data['allowFreeInput'] as bool?) ?? false;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.trpg.chooseAction, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...choices.map((choice) {
              final c = choice as Map<String, dynamic>;
              final id = c['id'] as String? ?? '';
              final text = c['text'] as String? ?? '';
              final hint = c['hint'] as String?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => onChoice(id, text),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text),
                      if (hint != null)
                        Text(
                          hint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            if (allowFreeInput) ...[
              const Divider(),
              Text(t.trpg.freeInput, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
