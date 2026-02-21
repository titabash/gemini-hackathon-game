import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';

import '../engine/base_game.dart';

/// A convenience wrapper around [RiverpodAwareGameWidget] that adds
/// [ClipRect] and default loading / error builders.
class GameContainer extends StatefulWidget {
  const GameContainer({
    super.key,
    required this.game,
    this.overlayBuilderMap,
    this.initialActiveOverlays,
    this.loadingBuilder,
    this.errorBuilder,
    this.backgroundBuilder,
  });

  /// The Flame game instance to render.
  final BaseGame game;

  /// Named overlay builders rendered on top of the game canvas.
  final Map<String, OverlayWidgetBuilder<BaseGame>>? overlayBuilderMap;

  /// Overlay names that should be active on startup.
  final List<String>? initialActiveOverlays;

  /// Builder shown while the game is loading.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder shown when the game encounters an error.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Builder for the background behind the game canvas.
  final Widget Function(BuildContext context)? backgroundBuilder;

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  final _gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<BaseGame>>();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: RiverpodAwareGameWidget<BaseGame>(
        key: _gameWidgetKey,
        game: widget.game,
        overlayBuilderMap: widget.overlayBuilderMap,
        initialActiveOverlays: widget.initialActiveOverlays,
        loadingBuilder:
            widget.loadingBuilder ??
            (context) =>
                const Center(child: CircularProgressIndicator.adaptive()),
        errorBuilder:
            widget.errorBuilder ??
            (context, error) => Center(
              child: Text(
                'Game error: $error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        backgroundBuilder: widget.backgroundBuilder,
      ),
    );
  }
}
