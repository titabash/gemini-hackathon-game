import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../model/login_form_state.dart';

/// メールアドレス入力フィールド
class EmailInputField extends ConsumerWidget {
  const EmailInputField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(loginEmailErrorProvider);

    return TextField(
      onChanged: (value) {
        ref.read(loginEmailProvider.notifier).update(value);
      },
      decoration: InputDecoration(
        labelText: 'メールアドレス',
        hintText: 'example@example.com',
        errorText: error,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
    );
  }
}
