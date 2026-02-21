import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../model/verify_otp_form_state.dart';

/// OTP入力フィールド
class OtpInputField extends ConsumerWidget {
  const OtpInputField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(verifyOtpTokenErrorProvider);

    return TextField(
      onChanged: (value) {
        ref.read(verifyOtpTokenProvider.notifier).update(value);
      },
      decoration: InputDecoration(
        labelText: '認証コード',
        hintText: '123456',
        errorText: error,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        helperText: 'メールに送信された6桁の認証コードを入力してください',
      ),
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      autofillHints: const [AutofillHints.oneTimeCode],
    );
  }
}
