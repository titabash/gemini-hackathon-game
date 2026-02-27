import 'scene_node.dart';

/// NPC asset entry with default image and per-emotion image URLs.
class NpcAssetEntry {
  const NpcAssetEntry({this.defaultUrl, this.emotionUrls = const {}});

  /// Resolved URL for the default NPC image, or null if not available.
  final String? defaultUrl;

  /// Emotion name → resolved URL mapping.
  final Map<String, String> emotionUrls;
}

const _scenarioAssetsBucket = 'scenario-assets';
const _generatedImagesBucket = 'generated-images';

/// Build a background asset map from DB rows.
///
/// Each row is expected to have `id`, `scenario_id`, `session_id`,
/// `image_path`, and `description` fields.
///
/// Returns a map keyed by both `id` and `description` → resolved URL.
/// Rows with null or empty `image_path` are skipped.
Map<String, String> buildBackgroundAssetMap(
  List<Map<String, dynamic>> rows,
  String Function(String) resolveUrl,
) {
  final map = <String, String>{};
  for (final row in rows) {
    final imagePath = row['image_path'] as String?;
    if (imagePath == null || imagePath.isEmpty) continue;

    final hasScenario = row['scenario_id'] != null;
    final bucket = hasScenario ? _scenarioAssetsBucket : _generatedImagesBucket;
    final resolved = resolveUrl('$bucket/$imagePath');

    final id = row['id'] as String?;
    if (id != null) map[id] = resolved;

    final description = row['description'] as String?;
    if (description != null && description.isNotEmpty) {
      map[description] = resolved;
    }
  }
  return map;
}

/// Build an NPC asset map from DB rows.
///
/// Each row is expected to have `name`, `image_path`, and
/// `emotion_images` (`Map<String, String>?` or null) fields.
///
/// NPC images always use the `scenario-assets` bucket.
Map<String, NpcAssetEntry> buildNpcAssetMap(
  List<Map<String, dynamic>> rows,
  String Function(String) resolveUrl,
) {
  final map = <String, NpcAssetEntry>{};
  for (final row in rows) {
    final name = row['name'] as String? ?? '';
    if (name.isEmpty) continue;

    final imagePath = row['image_path'] as String?;
    final defaultUrl = imagePath != null && imagePath.isNotEmpty
        ? resolveUrl('$_scenarioAssetsBucket/$imagePath')
        : null;

    final rawEmotions = row['emotion_images'] as Map<String, dynamic>?;
    final emotionUrls = <String, String>{};
    if (rawEmotions != null) {
      for (final entry in rawEmotions.entries) {
        final emotionPath = entry.value as String?;
        if (emotionPath != null && emotionPath.isNotEmpty) {
          emotionUrls[entry.key] = resolveUrl(
            '$_scenarioAssetsBucket/$emotionPath',
          );
        }
      }
    }

    map[name] = NpcAssetEntry(defaultUrl: defaultUrl, emotionUrls: emotionUrls);
  }
  return map;
}

/// Find the effective background by searching backwards from [fromIndex].
///
/// Returns the first non-null `background` value, or null if none found.
String? findEffectiveBackground(List<SceneNode> nodes, int fromIndex) {
  if (nodes.isEmpty) return null;
  final clampedIndex = fromIndex >= nodes.length ? nodes.length - 1 : fromIndex;
  for (var i = clampedIndex; i >= 0; i--) {
    if (nodes[i].background != null) return nodes[i].background;
  }
  return null;
}

/// Normalize a BGM mood string: trim + lowercase, empty becomes null.
String? normalizeMood(String? mood) {
  final normalized = (mood ?? '').trim().toLowerCase();
  return normalized.isEmpty ? null : normalized;
}

/// Resolve the effective BGM mood at [targetIndex] by scanning nodes 0..[targetIndex].
///
/// Returns the last active mood considering `bgm` and `bgmStop` directives,
/// or null if no BGM is active at the given position.
String? resolveNodeBgmMoodAtIndex(List<SceneNode> nodes, int targetIndex) {
  if (nodes.isEmpty) return null;
  final end = targetIndex.clamp(0, nodes.length - 1);

  String? activeMood;
  for (var i = 0; i <= end; i++) {
    final node = nodes[i];
    final mood = normalizeMood(node.bgm);
    if (node.bgmStop && mood == null) {
      activeMood = null;
    }
    if (mood != null) {
      activeMood = mood;
    }
  }
  return activeMood;
}

/// Build a summary text from scene nodes.
///
/// Dialogue nodes include `[speaker] text`, narration nodes use text only.
String buildNodesSummary(List<SceneNode> nodes) {
  return nodes
      .map((n) {
        if (n.speaker != null) return '[${n.speaker}] ${n.text}';
        return n.text;
      })
      .join('\n');
}
