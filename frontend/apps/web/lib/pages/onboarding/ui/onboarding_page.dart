import 'package:core_i18n/generated/strings.g.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/onboarding/api/check_account_name_availability.dart';
import '../../../features/onboarding/api/update_user_profile.dart';
import '../../../features/onboarding/model/onboarding_form_state.dart';
import '../../../features/onboarding/model/onboarding_status_provider.dart';
import '../../../features/onboarding/ui/account_name_input_field.dart';
import '../../../features/onboarding/ui/display_name_input_field.dart';

/// オンボーディングページ（プロフィール初期設定）
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isFormValid = ref.watch(isOnboardingFormValidProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.onboarding.title)),
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
                  Icons.person_add_outlined,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                Text(
                  t.onboarding.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t.onboarding.description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const AccountNameInputField(),
                const SizedBox(height: 16),
                const DisplayNameInputField(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting || !isFormValid
                      ? null
                      : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.onboarding.complete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final accountName = ref.read(onboardingAccountNameProvider);
      final displayName = ref.read(onboardingDisplayNameProvider);

      // アカウント名の重複チェック
      final isAvailable = await checkAccountNameAvailability(
        supabase: supabase,
        accountName: accountName,
      );

      if (!mounted) return;

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.onboarding.accountNameTaken),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // プロフィール更新
      await updateUserProfile(
        supabase: supabase,
        userId: userId,
        accountName: accountName,
        displayName: displayName,
      );

      // オンボーディング状態をリフレッシュ
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(needsOnboardingProvider);

      // フォームクリア
      ref.read(onboardingAccountNameProvider.notifier).clear();
      ref.read(onboardingDisplayNameProvider.notifier).clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.onboarding.success),
          backgroundColor: Colors.green,
        ),
      );
    } on Exception catch (e, st) {
      Logger.error('Onboarding failed', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.error.generic), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
