import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

/// Renders a simple continue button for narrate-type GM responses.
class ContinueButtonWidget extends StatelessWidget {
  const ContinueButtonWidget({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: FilledButton.tonal(
          onPressed: onContinue,
          child: Text(t.trpg.continueButton),
        ),
      ),
    );
  }
}
