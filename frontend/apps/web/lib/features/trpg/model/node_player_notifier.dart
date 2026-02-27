import 'package:flutter/foundation.dart';

import 'scene_node.dart';

/// Manages visual novel node-by-node playback with asset readiness gating.
///
/// Nodes are loaded from the backend [nodesReady] SSE event. Each node may
/// reference a background asset that must be resolved via [onAssetReady]
/// before the player can display it. If the current node's required asset
/// is not yet resolved, [isWaitingForAsset] is true and [advance] still
/// moves forward but the UI should show a loading state.
class NodePlayerNotifier {
  final _currentNodeNotifier = ValueNotifier<SceneNode?>(null);
  final _isCompleteNotifier = ValueNotifier<bool>(true);
  final _isWaitingForAssetNotifier = ValueNotifier<bool>(false);

  List<SceneNode> _nodes = [];
  int _currentIndex = 0;
  final Map<String, String> _resolvedAssets = {};
  String? _inheritedBackground;

  /// The scene node currently displayed.
  ValueListenable<SceneNode?> get currentNode => _currentNodeNotifier;

  /// Whether all nodes have been shown.
  ValueListenable<bool> get isComplete => _isCompleteNotifier;

  /// Whether the current node is blocked waiting for an asset.
  ValueListenable<bool> get isWaitingForAsset => _isWaitingForAssetNotifier;

  /// Current node index.
  int get currentIndex => _currentIndex;

  /// Total number of loaded nodes.
  int get nodeCount => _nodes.length;

  /// The effective background key for the current node, considering
  /// inheritance from previous nodes and previous turns.
  String? get effectiveBackground {
    for (var i = _currentIndex; i >= 0; i--) {
      if (i < _nodes.length && _nodes[i].background != null) {
        return _nodes[i].background;
      }
    }
    return _inheritedBackground;
  }

  /// Load a list of scene nodes for playback.
  void loadNodes(List<SceneNode> nodes) {
    if (_nodes.isNotEmpty) {
      _inheritedBackground = effectiveBackground;
    }
    _nodes = List.unmodifiable(nodes);
    _currentIndex = 0;

    if (_nodes.isEmpty) {
      _currentNodeNotifier.value = null;
      _isCompleteNotifier.value = true;
      _isWaitingForAssetNotifier.value = false;
      return;
    }

    _currentNodeNotifier.value = _nodes[0];
    _isCompleteNotifier.value = false;
    _updateAssetWaiting();
  }

  /// Notify that an asset has been resolved and is ready for display.
  void onAssetReady(String key, String path) {
    _resolvedAssets[key] = path;
    _updateAssetWaiting();
  }

  /// Get the resolved URL for an asset key, or null if not yet resolved.
  String? resolvedAssetUrl(String key) => _resolvedAssets[key];

  /// Advance to the next node.
  ///
  /// Returns `true` if advanced, `false` if already at the last node
  /// (marks playback as complete).
  bool advance() {
    if (_nodes.isEmpty || _currentIndex >= _nodes.length - 1) {
      _isCompleteNotifier.value = true;
      return false;
    }

    _currentIndex++;
    _currentNodeNotifier.value = _nodes[_currentIndex];

    if (_currentIndex >= _nodes.length - 1) {
      // At the last node but not yet complete (user still needs to read it)
    }

    _updateAssetWaiting();
    return true;
  }

  /// Reset all state.
  void clear() {
    _nodes = [];
    _currentIndex = 0;
    _resolvedAssets.clear();
    _inheritedBackground = null;
    _currentNodeNotifier.value = null;
    _isCompleteNotifier.value = true;
    _isWaitingForAssetNotifier.value = false;
  }

  /// Release resources.
  void dispose() {
    _currentNodeNotifier.dispose();
    _isCompleteNotifier.dispose();
    _isWaitingForAssetNotifier.dispose();
  }

  /// Check if the current node's effective background asset is resolved.
  void _updateAssetWaiting() {
    final bg = effectiveBackground;
    if (bg == null) {
      _isWaitingForAssetNotifier.value = false;
      return;
    }
    _isWaitingForAssetNotifier.value = !_resolvedAssets.containsKey(bg);
  }
}
