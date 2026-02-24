import 'trpg_session_provider.dart';

/// Converts a list of turn rows from the database into a flat list of
/// [TrpgMessage] objects for the conversation log.
///
/// Each turn row is expected to have `turn_number`, `input_type`,
/// `input_text`, and `output` fields.
///
/// For each turn:
/// - Non-start turns emit a user message from `input_text`.
/// - If `output.nodes[]` exists, each node becomes a GM message.
/// - Otherwise, `output.narration_text` is used as a single GM fallback.
List<TrpgMessage> parseTurnsToMessages(List<Map<String, dynamic>> turnRows) {
  final messages = <TrpgMessage>[];

  for (final row in turnRows) {
    final turnNumber = row['turn_number'] as int? ?? 0;
    final inputType = row['input_type'] as String? ?? '';
    final inputText = row['input_text'] as String? ?? '';
    final output = row['output'] as Map<String, dynamic>?;

    // User message (skip for 'start' turns)
    if (inputType != 'start') {
      messages.add(
        TrpgMessage(role: 'user', text: inputText, turnNumber: turnNumber),
      );
    }

    if (output == null) continue;

    // Try node-based output first
    final rawNodes = output['nodes'] as List<dynamic>?;
    if (rawNodes != null && rawNodes.isNotEmpty) {
      for (final rawNode in rawNodes) {
        final node = rawNode as Map<String, dynamic>;
        messages.add(
          TrpgMessage(
            role: 'gm',
            text: node['text'] as String? ?? '',
            turnNumber: turnNumber,
            speaker: node['speaker'] as String?,
          ),
        );
      }
      continue;
    }

    // Legacy fallback: narration_text
    final narrationText = output['narration_text'] as String?;
    if (narrationText != null && narrationText.isNotEmpty) {
      messages.add(
        TrpgMessage(role: 'gm', text: narrationText, turnNumber: turnNumber),
      );
    }
  }

  return messages;
}
