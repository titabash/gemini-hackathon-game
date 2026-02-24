import 'package:core_auth/core_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../entities/session/model/game_session.dart';

part 'fetch_active_sessions.g.dart';

/// シナリオ別のアクティブセッション一覧を取得するProvider
///
/// RLS により user_id = auth.uid() は自動保証される。
/// updated_at DESC でソートし、最新のセッションを先頭に返す。
@riverpod
Future<List<GameSession>> fetchActiveSessions(
  Ref ref, {
  required String scenarioId,
}) async {
  final supabase = ref.read(supabaseClientProvider);
  final response = await supabase
      .from('sessions')
      .select()
      .eq('scenario_id', scenarioId)
      .eq('status', 'active')
      .order('updated_at', ascending: false);

  return (response as List)
      .map((row) => GameSession.fromJson(row as Map<String, dynamic>))
      .toList();
}
