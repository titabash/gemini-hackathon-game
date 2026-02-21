import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../model/onboarding_form_state.dart';

/// アカウント名入力フィールド
class AccountNameInputField extends ConsumerWidget {
  const AccountNameInputField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(onboardingAccountNameErrorProvider);

    return TextField(
      onChanged: (value) =>
          ref.read(onboardingAccountNameProvider.notifier).update(value),
      decoration: InputDecoration(
        labelText: t.onboarding.accountName,
        hintText: t.onboarding.accountNameHint,
        helperText: t.onboarding.accountNameHelper,
        errorText: _mapError(error),
        prefixIcon: const Icon(Icons.alternate_email),
      ),
      keyboardType: TextInputType.text,
      autocorrect: false,
    );
  }

  String? _mapError(String? errorKey) {
    if (errorKey == null) return null;
    return switch (errorKey) {
      'tooShort' => t.onboarding.accountNameTooShort,
      'tooLong' => t.onboarding.accountNameTooLong,
      'invalidFormat' => t.onboarding.accountNameInvalidFormat,
      'temporary' => t.onboarding.accountNameTemporary,
      'taken' => t.onboarding.accountNameTaken,
      _ => errorKey,
    };
  }
}
