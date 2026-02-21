import 'package:core_i18n/generated/strings.g.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/scenario_detail/api/fetch_scenario.dart';
import '../../../features/start_game/api/create_session.dart';
import '../../../shared/ui/storage_image.dart';

/// ゲーム詳細ページ
class GameDetailPage extends ConsumerWidget {
  const GameDetailPage({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarioAsync = ref.watch(
      fetchScenarioProvider(scenarioId: scenarioId),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: scenarioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(t.scenarioList.error),
            ],
          ),
        ),
        data: (scenario) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ヒーロー画像
              AspectRatio(
                aspectRatio: 16 / 9,
                child: StorageImage(
                  storagePath: scenario.thumbnailPath,
                  bucket: 'scenario-assets',
                  placeholder: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.videogame_asset,
                        size: 80,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    Text(
                      scenario.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 説明
                    if (scenario.description.isNotEmpty) ...[
                      Text(
                        t.scenarioDetail.description,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scenario.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                    ],
                    // プレイボタン
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _startGame(context, ref),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(t.scenarioDetail.play),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startGame(BuildContext context, WidgetRef ref) async {
    try {
      final session = await ref
          .read(createSessionProvider.notifier)
          .create(scenarioId: scenarioId);

      if (!context.mounted) return;
      context.go('/game/${session.id}');
    } catch (e, st) {
      Logger.error('Failed to start game', e, st);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scenarioDetail.startError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
