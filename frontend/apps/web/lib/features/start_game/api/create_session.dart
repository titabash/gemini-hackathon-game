import 'package:core_auth/core_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../entities/session/model/game_session.dart';

part 'create_session.g.dart';

/// ゲームセッションを作成するProvider
@Riverpod(keepAlive: true)
class CreateSession extends _$CreateSession {
  @override
  Future<GameSession?> build() async {
    return null;
  }

  /// シナリオからセッションを新規作成
  Future<GameSession> create({required String scenarioId}) async {
    state = const AsyncLoading();

    // async前に依存を取得（dispose後のref使用を防ぐ）
    final supabase = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);

    final result = await AsyncValue.guard(() async {
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // シナリオの initial_state を取得
      final scenarioResponse = await supabase
          .from('scenarios')
          .select('initial_state, title')
          .eq('id', scenarioId)
          .single();

      final initialState =
          scenarioResponse['initial_state'] as Map<String, dynamic>;
      final scenarioTitle = scenarioResponse['title'] as String;

      // セッション作成
      final insertedRows = await supabase.from('sessions').insert({
        'user_id': user.id,
        'scenario_id': scenarioId,
        'title': scenarioTitle,
        'status': 'active',
        'current_state': initialState,
        'current_turn_number': 0,
      }).select();

      final row = (insertedRows as List).first as Map<String, dynamic>;

      return GameSession(
        id: row['id'] as String? ?? '',
        userId: user.id,
        scenarioId: scenarioId,
        title: scenarioTitle,
        currentState: initialState,
      );
    });

    state = result;
    return result.requireValue;
  }
}
