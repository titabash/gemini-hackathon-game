import 'package:core_auth/core_auth.dart';
import 'package:core_i18n/core_i18n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../features/scenario_list/api/fetch_scenarios.dart';
import '../../../features/scenario_list/ui/scenario_card.dart';

/// ゲーム一覧ページ（認証後のメインページ）
class GameListPage extends ConsumerWidget {
  const GameListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(fetchScenariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.scenarioList.title),
        actions: [
          const LanguageSelectorWidget(),
          IconButton(
            onPressed: () => _handleLogout(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: t.scenarioList.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(fetchScenariosProvider.notifier).refresh(),
        child: scenariosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(t.scenarioList.error),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(fetchScenariosProvider.notifier).refresh(),
                  child: Text(t.common.retry),
                ),
              ],
            ),
          ),
          data: (scenarios) {
            if (scenarios.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videogame_asset_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.scenarioList.empty,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.scenarioList.emptyDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: scenarios.length,
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                return ScenarioCard(
                  scenario: scenario,
                  onTap: () => context.go('/scenarios/${scenario.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
  }
}
