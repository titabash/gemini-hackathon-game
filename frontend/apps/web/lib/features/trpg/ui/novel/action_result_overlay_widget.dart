import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../model/change_event.dart';

/// Design constants for change event visual effects.
abstract final class _EffectColors {
  static const negative = Color(0xFFE53935);
  static const positive = Color(0xFF43A047);
  static const acquire = Color(0xFFFFA726);
  static const effect = Color(0xFFAB47BC);
  static const objective = Color(0xFF42A5F5);
  static const relationAffinity = Color(0xFFEC407A);
  static const relationTrust = Color(0xFF29B6F6);
  static const relationFear = Color(0xFF7E57C2);
  static const relationDebt = Color(0xFFFFCA28);
  static const loss = Color(0xFF757575);
}

/// Full-screen overlay that animates visual feedback for game state changes.
///
/// Listens to [pendingChanges] and dispatches animations across three layers:
/// 1. Screen tint (full-screen colour flash)
/// 2. Centre floating text (stat / effect changes)
/// 3. Top banner notification queue (items / objectives / relationships)
class ActionResultOverlayWidget extends StatefulWidget {
  const ActionResultOverlayWidget({super.key, required this.pendingChanges});

  final ValueListenable<List<ChangeEvent>> pendingChanges;

  @override
  State<ActionResultOverlayWidget> createState() =>
      _ActionResultOverlayWidgetState();
}

class _ActionResultOverlayWidgetState extends State<ActionResultOverlayWidget>
    with TickerProviderStateMixin {
  final _tintEntries = <_TintEntry>[];
  final _floatingEntries = <_FloatingEntry>[];
  final _bannerQueue = <_BannerData>[];
  _BannerData? _activeBanner;

  @override
  void initState() {
    super.initState();
    widget.pendingChanges.addListener(_onChanges);
  }

  @override
  void didUpdateWidget(ActionResultOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pendingChanges != widget.pendingChanges) {
      oldWidget.pendingChanges.removeListener(_onChanges);
      widget.pendingChanges.addListener(_onChanges);
    }
  }

  @override
  void dispose() {
    widget.pendingChanges.removeListener(_onChanges);
    for (final e in _tintEntries) {
      e.controller.dispose();
    }
    for (final e in _floatingEntries) {
      e.controller.dispose();
    }
    _activeBanner?.controller?.dispose();
    super.dispose();
  }

  void _onChanges() {
    final events = widget.pendingChanges.value;
    if (events.isEmpty) return;

    var floatingIndex = 0;
    for (final event in events) {
      switch (event) {
        case StatChangeEvent():
          _addFloatingText(event, floatingIndex++);
          _addTint(
            event.delta < 0 ? _EffectColors.negative : _EffectColors.positive,
          );
        case StatusEffectAddedEvent():
          _addFloatingText(event, floatingIndex++);
          _addTint(_EffectColors.effect);
        case StatusEffectRemovedEvent():
          _addFloatingText(event, floatingIndex++);
        case LocationChangedEvent():
          _addLocationTransition(event);
        case ItemAcquiredEvent():
          _enqueueBanner(event);
        case ItemRemovedEvent():
          _enqueueBanner(event);
        case ObjectiveUpdatedEvent():
          _enqueueBanner(event);
        case RelationshipChangedEvent():
          _enqueueBanner(event);
      }
    }
  }

  // -- Screen tint -----------------------------------------------------------

  void _addTint(Color color) {
    if (!mounted) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final entry = _TintEntry(color: color, controller: controller);
    setState(() => _tintEntries.add(entry));
    controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!mounted) return;
          setState(() => _tintEntries.remove(entry));
          controller.dispose();
        }
      })
      ..forward();
  }

  // -- Centre floating text --------------------------------------------------

  void _addFloatingText(ChangeEvent event, int index) {
    if (!mounted) return;
    final delay = Duration(milliseconds: index * 400);
    Future.delayed(delay, () {
      if (!mounted) return;
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2500),
      );
      final entry = _FloatingEntry(
        event: event,
        controller: controller,
        verticalOffset: index * 44.0,
      );
      setState(() => _floatingEntries.add(entry));
      controller
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            if (!mounted) return;
            setState(() => _floatingEntries.remove(entry));
            controller.dispose();
          }
        })
        ..forward();
    });
  }

  // -- Location transition ---------------------------------------------------

  void _addLocationTransition(LocationChangedEvent event) {
    if (!mounted) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    final entry = _FloatingEntry(
      event: event,
      controller: controller,
      verticalOffset: 0,
    );
    setState(() => _floatingEntries.add(entry));
    controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!mounted) return;
          setState(() => _floatingEntries.remove(entry));
          controller.dispose();
        }
      })
      ..forward();
  }

  // -- Banner queue ----------------------------------------------------------

  void _enqueueBanner(ChangeEvent event) {
    final data = _BannerData(event: event);
    _bannerQueue.add(data);
    _showNextBanner();
  }

  void _showNextBanner() {
    if (_activeBanner != null || _bannerQueue.isEmpty || !mounted) return;
    final data = _bannerQueue.removeAt(0);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    data.controller = controller;
    setState(() => _activeBanner = data);
    controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!mounted) return;
          setState(() => _activeBanner = null);
          controller.dispose();
          _showNextBanner();
        }
      })
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Screen tints
        for (final entry in _tintEntries) _ScreenTint(entry: entry),

        // Layer 2: Location cinematic overlay
        for (final entry in _floatingEntries)
          if (entry.event is LocationChangedEvent)
            _LocationOverlay(entry: entry),

        // Layer 3: Centre floating texts (non-location)
        for (final entry in _floatingEntries)
          if (entry.event is! LocationChangedEvent)
            _CentreFloatingText(entry: entry),

        // Layer 4: Banner notification
        if (_activeBanner != null) _BannerNotification(data: _activeBanner!),
      ],
    );
  }
}

// -- Data classes ------------------------------------------------------------

class _TintEntry {
  _TintEntry({required this.color, required this.controller});
  final Color color;
  final AnimationController controller;
}

class _FloatingEntry {
  _FloatingEntry({
    required this.event,
    required this.controller,
    required this.verticalOffset,
  });
  final ChangeEvent event;
  final AnimationController controller;
  final double verticalOffset;
}

class _BannerData {
  _BannerData({required this.event});
  final ChangeEvent event;
  AnimationController? controller;
}

// -- Screen tint widget ------------------------------------------------------

class _ScreenTint extends StatelessWidget {
  const _ScreenTint({required this.entry});
  final _TintEntry entry;

  @override
  Widget build(BuildContext context) {
    // 0→0.15 in first half, 0.15→0 in second half
    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0), weight: 1),
    ]).animate(entry.controller);

    return AnimatedBuilder(
      animation: opacity,
      builder: (context, _) {
        return Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: entry.color.withValues(alpha: opacity.value),
            ),
          ),
        );
      },
    );
  }
}

// -- Centre floating text widget ---------------------------------------------

class _CentreFloatingText extends StatelessWidget {
  const _CentreFloatingText({required this.entry});
  final _FloatingEntry entry;

  @override
  Widget build(BuildContext context) {
    final controller = entry.controller;

    // Scale: 0.8→1.1 (0-8%), 1.1→1.0 (8-16%), 1.0 hold
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.8,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 64),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
    ]).animate(controller);

    // Opacity: 0→1 (0-8%), 1 hold (8-80%), 1→0 (80-100%)
    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 72),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(controller);

    // Slide up: 0 → -30px in last 20%
    final slideY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -30.0), weight: 20),
    ]).animate(controller);

    final textInfo = _resolveFloatingText(entry.event);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: const Alignment(0, -0.15),
              child: Transform.translate(
                offset: Offset(0, slideY.value + entry.verticalOffset),
                child: Transform.scale(
                  scale: scale.value,
                  child: Opacity(
                    opacity: opacity.value.clamp(0.0, 1.0),
                    child: Text(
                      textInfo.text,
                      style: TextStyle(
                        color: textInfo.color,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// -- Location cinematic overlay ----------------------------------------------

class _LocationOverlay extends StatelessWidget {
  const _LocationOverlay({required this.entry});
  final _FloatingEntry entry;

  @override
  Widget build(BuildContext context) {
    final controller = entry.controller;
    final event = entry.event as LocationChangedEvent;

    // Darken: 0→0.6 (0-17%), 0.6 hold (17-83%), 0.6→0 (83-100%)
    final darken = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 17),
      TweenSequenceItem(tween: ConstantTween(0.6), weight: 66),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 17),
    ]).animate(controller);

    // Text opacity: 0 (0-17%), 0→1 (17-37%), 1 hold (37-83%), 1→0 (83-100%)
    final textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 17),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 46),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 17),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                // Darken layer
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: darken.value.clamp(0.0, 1.0),
                    ),
                  ),
                ),
                // Location name
                Center(
                  child: Opacity(
                    opacity: textOpacity.value.clamp(0.0, 1.0),
                    child: Text(
                      t.trpg.changes.locationChanged(name: event.locationName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -- Banner notification widget ----------------------------------------------

class _BannerNotification extends StatelessWidget {
  const _BannerNotification({required this.data});
  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    final controller = data.controller;
    if (controller == null) return const SizedBox.shrink();

    // Slide: -50→0 (0-10%), 0 hold (10-90%), 0→-50 (90-100%)
    final slideY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: -50.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 80),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -50.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
    ]).animate(controller);

    // Opacity: 0→1 (0-10%), 1 hold (10-90%), 1→0 (90-100%)
    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(controller);

    final bannerInfo = _resolveBannerInfo(data.event);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Transform.translate(
              offset: Offset(0, slideY.value),
              child: Opacity(
                opacity: opacity.value.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bannerInfo.color.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(bannerInfo.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bannerInfo.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// -- Helpers -----------------------------------------------------------------

class _TextInfo {
  const _TextInfo({required this.text, required this.color});
  final String text;
  final Color color;
}

class _BannerInfo {
  const _BannerInfo({
    required this.text,
    required this.color,
    required this.icon,
  });
  final String text;
  final Color color;
  final IconData icon;
}

_TextInfo _resolveFloatingText(ChangeEvent event) {
  return switch (event) {
    StatChangeEvent(:final statKey, :final delta) => _TextInfo(
      text: delta < 0
          ? t.trpg.changes.statDecrease(
              key: statKey.toUpperCase(),
              delta: delta.toString(),
            )
          : t.trpg.changes.statIncrease(
              key: statKey.toUpperCase(),
              delta: delta.toString(),
            ),
      color: delta < 0 ? _EffectColors.negative : _EffectColors.positive,
    ),
    StatusEffectAddedEvent(:final effectName) => _TextInfo(
      text: t.trpg.changes.effectAdded(name: effectName),
      color: _EffectColors.effect,
    ),
    StatusEffectRemovedEvent(:final effectName) => _TextInfo(
      text: t.trpg.changes.effectRemoved(name: effectName),
      color: Colors.white,
    ),
    _ => const _TextInfo(text: '', color: Colors.white),
  };
}

_BannerInfo _resolveBannerInfo(ChangeEvent event) {
  return switch (event) {
    ItemAcquiredEvent(:final itemName) => _BannerInfo(
      text: t.trpg.changes.itemAcquired(name: itemName),
      color: _EffectColors.acquire,
      icon: Icons.star,
    ),
    ItemRemovedEvent(:final itemName) => _BannerInfo(
      text: t.trpg.changes.itemRemoved(name: itemName),
      color: _EffectColors.loss,
      icon: Icons.remove_circle_outline,
    ),
    ObjectiveUpdatedEvent(:final title, :final status) => _BannerInfo(
      text: switch (status) {
        'completed' => t.trpg.changes.objectiveCompleted(title: title),
        'failed' => t.trpg.changes.objectiveFailed(title: title),
        _ => t.trpg.changes.objectiveNew(title: title),
      },
      color: switch (status) {
        'completed' => _EffectColors.positive,
        'failed' => _EffectColors.negative,
        _ => _EffectColors.objective,
      },
      icon: switch (status) {
        'completed' => Icons.check_circle,
        'failed' => Icons.cancel,
        _ => Icons.flag,
      },
    ),
    RelationshipChangedEvent(
      :final npcName,
      :final affinityDelta,
      :final trustDelta,
      :final fearDelta,
      :final debtDelta,
    ) =>
      _resolveRelationshipBanner(
        npcName,
        affinityDelta,
        trustDelta,
        fearDelta,
        debtDelta,
      ),
    _ => const _BannerInfo(
      text: '',
      color: _EffectColors.loss,
      icon: Icons.info,
    ),
  };
}

_BannerInfo _resolveRelationshipBanner(
  String npcName,
  int affinityDelta,
  int trustDelta,
  int fearDelta,
  int debtDelta,
) {
  // Pick the largest absolute change to display
  final deltas = {
    t.trpg.affinity: (affinityDelta, _EffectColors.relationAffinity),
    t.trpg.trust: (trustDelta, _EffectColors.relationTrust),
    t.trpg.fear: (fearDelta, _EffectColors.relationFear),
    t.trpg.debt: (debtDelta, _EffectColors.relationDebt),
  };
  var bestDimension = t.trpg.affinity;
  var bestDelta = 0;
  var bestColor = _EffectColors.relationAffinity;
  for (final e in deltas.entries) {
    if (e.value.$1.abs() > bestDelta.abs()) {
      bestDimension = e.key;
      bestDelta = e.value.$1;
      bestColor = e.value.$2;
    }
  }
  final text = bestDelta > 0
      ? t.trpg.changes.relationUp(
          npc: npcName,
          dimension: bestDimension,
          delta: bestDelta.toString(),
        )
      : t.trpg.changes.relationDown(
          npc: npcName,
          dimension: bestDimension,
          delta: bestDelta.toString(),
        );
  return _BannerInfo(
    text: text,
    color: bestColor,
    icon: bestDelta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
  );
}
