import 'package:flutter/material.dart';

import '../../../entities/scenario/model/scenario.dart';
import '../../../shared/ui/storage_image.dart';

/// シナリオカード - ゲーム一覧の各アイテム
class ScenarioCard extends StatelessWidget {
  const ScenarioCard({super.key, required this.scenario, required this.onTap});

  final Scenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // サムネイル領域
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
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            // テキスト領域
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (scenario.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      scenario.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
