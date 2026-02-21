import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

/// Renders a GM clarification question.
class ClarifyQuestionWidget extends StatelessWidget {
  const ClarifyQuestionWidget({
    super.key,
    required this.data,
    required this.onAnswer,
  });

  final Map<String, dynamic> data;
  final void Function(String answer) onAnswer;

  @override
  Widget build(BuildContext context) {
    final question = data['question'] as String? ?? '';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, size: 20),
                const SizedBox(width: 8),
                Text(t.trpg.clarifyTitle, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(question, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
