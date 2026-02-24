import 'package:core_auth/core_auth.dart';
import 'package:core_game/core_game.dart';
import 'package:core_i18n/generated/strings.g.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../entities/scenario/model/scenario.dart';
import '../../../features/start_game/api/create_session.dart';
import '../api/fetch_active_sessions.dart';
import 'menu_game.dart';

/// ゲームメニュー画面のUI
///
/// ノベルゲーム風タイトル画面。
/// 背景画像の上部にタイトルを大きく配置し、
/// 下部中央に半透明パネル内のテキストメニューを表示する。
class GameMenuSurface extends ConsumerStatefulWidget {
  const GameMenuSurface({super.key, required this.scenario});

  final Scenario scenario;

  @override
  ConsumerState<GameMenuSurface> createState() => _GameMenuSurfaceState();
}

class _GameMenuSurfaceState extends ConsumerState<GameMenuSurface> {
  late final MenuGame _game;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    final supabase = ref.read(supabaseClientProvider);
    final thumbnailUrl = widget.scenario.thumbnailPath != null
        ? supabase.storage
              .from('scenario-assets')
              .getPublicUrl(widget.scenario.thumbnailPath!)
        : null;
    _game = MenuGame(thumbnailUrl: thumbnailUrl);
  }

  Future<void> _onNewGame() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final session = await ref
          .read(createSessionProvider.notifier)
          .create(scenarioId: widget.scenario.id);

      if (!mounted) return;
      context.go('/game/${session.id}');
    } catch (e, st) {
      Logger.error('Failed to start new game', e, st);
      if (!mounted) return;
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.scenarioDetail.startError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onLoad() {
    context.go('/scenarios/${widget.scenario.id}/menu/saves');
  }

  void _onBack() {
    context.go('/scenarios/${widget.scenario.id}');
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(
      fetchActiveSessionsProvider(scenarioId: widget.scenario.id),
    );
    final hasActiveSessions =
        sessionsAsync.whenOrNull(data: (sessions) => sessions.isNotEmpty) ??
        false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1: Flame background (full bleed)
          Positioned.fill(child: GameContainer(game: _game)),

          // Layer 2: Menu content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // -- Title area (upper ~45%) --
                  const Spacer(flex: 2),
                  _TitleDisplay(title: widget.scenario.title),
                  const Spacer(flex: 3),

                  // -- Menu panel (lower center) --
                  _MenuPanel(
                    isStarting: _isStarting,
                    hasActiveSessions: hasActiveSessions,
                    onNewGame: _onNewGame,
                    onLoad: _onLoad,
                    onBack: _onBack,
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Title display - large title with shadow/glow
// ---------------------------------------------------------------------------

class _TitleDisplay extends StatelessWidget {
  const _TitleDisplay({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.2,
          letterSpacing: 4,
          shadows: [
            Shadow(blurRadius: 16, color: Colors.black87),
            Shadow(blurRadius: 32, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu panel - semi-transparent box with text menu items
// ---------------------------------------------------------------------------

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.isStarting,
    required this.hasActiveSessions,
    required this.onNewGame,
    required this.onLoad,
    required this.onBack,
  });

  final bool isStarting;
  final bool hasActiveSessions;
  final VoidCallback onNewGame;
  final VoidCallback onLoad;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuItem(
              label: t.gameMenu.newGame,
              onTap: isStarting ? null : onNewGame,
              isLoading: isStarting,
            ),
            if (hasActiveSessions) ...[
              const SizedBox(height: 20),
              _MenuItem(label: t.gameMenu.loadGame, onTap: onLoad),
            ],
            const SizedBox(height: 20),
            _MenuItem(label: t.gameMenu.backToTitle, onTap: onBack),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single menu item - text button with hover effect
// ---------------------------------------------------------------------------

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 3,
            color: widget.onTap == null
                ? Colors.white38
                : _isHovered
                ? Colors.white
                : Colors.white70,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hover indicator
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHovered && widget.onTap != null ? 1.0 : 0.0,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    '\u25B6',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
              if (widget.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                )
              else
                Text(widget.label),
            ],
          ),
        ),
      ),
    );
  }
}
