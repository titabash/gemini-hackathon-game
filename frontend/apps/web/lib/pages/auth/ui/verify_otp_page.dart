import 'package:core_auth/core_auth.dart';
import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../features/auth/api/verify_otp.dart';
import '../../../features/auth/api/send_otp.dart';
import '../../../features/auth/model/verify_otp_form_state.dart';
import '../../../features/auth/ui/otp_input_field.dart';

/// OTP検証ページ
class VerifyOtpPage extends ConsumerWidget {
  const VerifyOtpPage({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = ref.watch(isVerifyOtpFormValidProvider);
    final verifyOtpState = ref.watch(verifyOtpProvider);
    final isLoading = verifyOtpState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(t.auth.verifyCode)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                Text(
                  t.auth.enterCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t.auth.enterCodeDescription(email: email),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const OtpInputField(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading || !isFormValid
                      ? null
                      : () => _handleVerifyOtp(context, ref),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.auth.loginButton),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _handleResendOtp(context, ref),
                  child: Text(t.auth.resendCode),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(verifyOtpTokenProvider.notifier).clear();
                    context.go('/login');
                  },
                  child: Text(t.auth.changeEmail),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerifyOtp(BuildContext context, WidgetRef ref) async {
    final token = ref.read(verifyOtpTokenProvider);
    final result = await ref
        .read(verifyOtpProvider.notifier)
        .call(email: email, token: token);

    if (!context.mounted) return;

    result.when(
      success: (_) {
        ref.read(verifyOtpTokenProvider.notifier).clear();
        context.go('/');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.auth.loginSuccess),
            backgroundColor: Colors.green,
          ),
        );
      },
      failure: (exception) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exception.message),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _handleResendOtp(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(sendOtpProvider.notifier).call(email);

    if (!context.mounted) return;

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.auth.codeResent(email: email)),
            backgroundColor: Colors.green,
          ),
        );
      },
      failure: (exception) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exception.message),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}
