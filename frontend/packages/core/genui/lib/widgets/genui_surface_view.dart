import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';

/// Renders the A2UI surface with [surfaceId] from [processor], or
/// [defaultBuilder] while no such surface exists.
///
/// Replaces genui's `GenUiSurface(host:, surfaceId:, defaultBuilder:)`, which
/// could be built before the surface was created and followed it by id.
class GenuiSurfaceView extends StatefulWidget {
  const GenuiSurfaceView({
    super.key,
    required this.processor,
    required this.surfaceId,
    this.defaultBuilder,
  });

  /// The processor that holds the surface.
  final MessageProcessor<ComponentImplementation> processor;

  /// The ID of the surface to render.
  final String surfaceId;

  /// Builds the widget shown while the surface does not exist.
  final WidgetBuilder? defaultBuilder;

  @override
  State<GenuiSurfaceView> createState() => _GenuiSurfaceViewState();
}

class _GenuiSurfaceViewState extends State<GenuiSurfaceView> {
  SurfaceModel<ComponentImplementation>? _surface;
  Subscription? _created;
  Subscription? _deleted;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(GenuiSurfaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.processor != widget.processor ||
        oldWidget.surfaceId != widget.surfaceId) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    final SurfaceGroupModel<ComponentImplementation> model =
        widget.processor.model;
    _surface = model.getSurface(widget.surfaceId);
    _created = model.onSurfaceCreated.subscribe((surface) {
      if (surface.id == widget.surfaceId) setState(() => _surface = surface);
    });
    _deleted = model.onSurfaceDeleted.subscribe((id) {
      if (id == widget.surfaceId) setState(() => _surface = null);
    });
  }

  void _unsubscribe() {
    _created?.unsubscribe();
    _deleted?.unsubscribe();
  }

  @override
  Widget build(BuildContext context) {
    final SurfaceModel<ComponentImplementation>? surface = _surface;
    if (surface == null) {
      return widget.defaultBuilder?.call(context) ?? const SizedBox.shrink();
    }
    return A2uiSurface(key: ObjectKey(surface), surface: surface);
  }
}
