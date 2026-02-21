import 'package:supabase_flutter/supabase_flutter.dart';

/// ユーザープロフィールを更新する（オンボーディング完了時）
Future<void> updateUserProfile({
  required SupabaseClient supabase,
  required String userId,
  required String accountName,
  required String displayName,
}) async {
  await supabase
      .from('users')
      .update({'account_name': accountName, 'display_name': displayName})
      .eq('id', userId);
}
