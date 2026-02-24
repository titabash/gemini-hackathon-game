import 'package:core_auth/core_auth.dart';
import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../entities/session/model/game_session.dart';
import '../api/fetch_active_sessions.dart';

/// セーブデータ一覧ページ（GridTile 表示）
///
/// 参考: ノベルゲームのセーブ/ロード画面風。
/// 固定スロット数のグリッドにセッションを配置し、
/// 空きスロットは "NO DATA" と表示する。
class SavedSessionGrid extends ConsumerWidget {
  const SavedSessionGrid({super.key, required this.scenarioId});

  final String scenarioId;

  static const _gridSlotCount = 12;
  static const _crossAxisCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(
      fetchActiveSessionsProvider(scenarioId: scenarioId),
    );
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        leading: IconButton(
          onPressed: () => context.go('/scenarios/$scenarioId/menu'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          t.gameMenu.savedSessions,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: sessionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                t.error.generic,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
        data: (sessions) => _buildGrid(context, ref, sessions),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<GameSession> sessions,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _gridSlotCount,
        itemBuilder: (context, index) {
          final session = index < sessions.length ? sessions[index] : null;
          return _SaveSlotTile(
            slotIndex: index + 1,
            session: session,
            scenarioId: scenarioId,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single save slot tile
// ---------------------------------------------------------------------------

class _SaveSlotTile extends ConsumerWidget {
  const _SaveSlotTile({
    required this.slotIndex,
    required this.session,
    required this.scenarioId,
  });

  final int slotIndex;
  final GameSession? session;
  final String scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = session != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasData ? () => context.go('/game/${session!.id}') : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF252540),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasData ? Colors.white24 : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Slot header
              _SlotHeader(
                slotIndex: slotIndex,
                hasData: hasData,
                session: session,
              ),

              // Thumbnail area
              Expanded(child: _SlotThumbnail(session: session)),

              // Info footer
              _SlotFooter(session: session),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slot header with index number
// ---------------------------------------------------------------------------

class _SlotHeader extends StatelessWidget {
  const _SlotHeader({
    required this.slotIndex,
    required this.hasData,
    this.session,
  });

  final int slotIndex;
  final bool hasData;
  final GameSession? session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasData ? Colors.white.withValues(alpha: 0.1) : Colors.white10,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasData
                  ? const Color(0xFF6644AA)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$slotIndex',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasData ? Colors.white : Colors.white38,
              ),
            ),
          ),
          if (hasData && session != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDateTime(session!.updatedAt),
                style: const TextStyle(fontSize: 10, color: Colors.white54),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('yyyy/MM/dd HH:mm').format(dt.toLocal());
  }
}

// ---------------------------------------------------------------------------
// Thumbnail area
// ---------------------------------------------------------------------------

class _SlotThumbnail extends ConsumerWidget {
  const _SlotThumbnail({required this.session});

  final GameSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session == null) {
      return Center(
        child: Text(
          t.gameMenu.noData,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white24,
            letterSpacing: 2,
          ),
        ),
      );
    }

    // Try to show scenario thumbnail as slot preview
    final supabase = ref.read(supabaseClientProvider);
    // Use a gradient placeholder with scenario info
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A4A), Color(0xFF1A1A3E)],
        ),
      ),
      child: Stack(
        children: [
          // Try loading scenario thumbnail
          if (session!.scenarioId.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _ScenarioThumbnail(
                  scenarioId: session!.scenarioId,
                  supabase: supabase,
                ),
              ),
            ),
          // Title overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              child: Text(
                session!.title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scenario thumbnail image
// ---------------------------------------------------------------------------

class _ScenarioThumbnail extends StatelessWidget {
  const _ScenarioThumbnail({required this.scenarioId, required this.supabase});

  final String scenarioId;
  final SupabaseClient supabase;

  @override
  Widget build(BuildContext context) {
    // Scenario thumbnail path follows convention: scenarios/{id}/thumbnail.png
    // But we don't have the exact path here, so show a styled placeholder
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A2A5A), Color(0xFF1A1A3E)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.videogame_asset, size: 32, color: Colors.white12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info footer
// ---------------------------------------------------------------------------

class _SlotFooter extends StatelessWidget {
  const _SlotFooter({required this.session});

  final GameSession? session;

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const SizedBox(height: 28);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Text(
        t.gameMenu.turnNumber(n: session!.currentTurnNumber),
        style: const TextStyle(fontSize: 11, color: Colors.white54),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
