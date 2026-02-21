import 'package:core_auth/core_auth.dart';
import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../features/auth/api/send_otp.dart';
import '../../../features/auth/model/login_form_state.dart';
import '../../../features/auth/ui/email_input_field.dart';

/// ログインページ（OTP送信）
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = ref.watch(isLoginFormValidProvider);
    final sendOtpState = ref.watch(sendOtpProvider);
    final isLoading = sendOtpState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(t.auth.login)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
                const SizedBox(height: 32),
                Text(
                  t.auth.loginWithEmail,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t.auth.loginDescription,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const EmailInputField(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading || !isFormValid
                      ? null
                      : () => _handleSendOtp(context, ref),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.auth.sendCode),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(t.auth.backToHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendOtp(BuildContext context, WidgetRef ref) async {
    final email = ref.read(loginEmailProvider);
    final result = await ref.read(sendOtpProvider.notifier).call(email);

    if (!context.mounted) return;

    result.when(
      success: (_) {
        ref.read(loginEmailProvider.notifier).clear();
        context.go('/verify-otp?email=${Uri.encodeComponent(email)}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.auth.codeSent(email: email)),
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
