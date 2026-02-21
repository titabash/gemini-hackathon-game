import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../entities/user/model/user_profile.dart';

/// ユーザープロフィールを取得する
Future<UserProfile?> fetchUserProfile({
  required SupabaseClient supabase,
  required String userId,
}) async {
  final data = await supabase
      .from('users')
      .select()
      .eq('id', userId)
      .maybeSingle();

  if (data == null) return null;
  return UserProfile.fromJson(data);
}
