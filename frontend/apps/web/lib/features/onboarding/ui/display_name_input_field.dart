import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../model/onboarding_form_state.dart';

/// 表示名入力フィールド
class DisplayNameInputField extends ConsumerWidget {
  const DisplayNameInputField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (value) =>
          ref.read(onboardingDisplayNameProvider.notifier).update(value),
      decoration: InputDecoration(
        labelText: t.onboarding.displayName,
        hintText: t.onboarding.displayNameHint,
        helperText: t.onboarding.displayNameHelper,
        prefixIcon: const Icon(Icons.person_outline),
      ),
      keyboardType: TextInputType.name,
    );
  }
}
