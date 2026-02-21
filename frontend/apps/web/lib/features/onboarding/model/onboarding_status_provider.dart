import 'package:core_auth/core_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../entities/user/model/user_profile.dart';

part 'onboarding_status_provider.g.dart';

/// 現在のユーザープロフィールを取得するProvider
@riverpod
Future<UserProfile?> currentUserProfile(Ref ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return null;

  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await supabase
      .from('users')
      .select()
      .eq('id', userId)
      .maybeSingle();

  if (data == null) return null;
  return UserProfile.fromJson(data);
}

/// オンボーディングが必要かどうかを判定するProvider
@riverpod
Future<bool> needsOnboarding(Ref ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile == null) return false;
  return profile.needsOnboarding;
}
