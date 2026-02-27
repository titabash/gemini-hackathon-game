import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/features/trpg/model/node_player_notifier.dart';
import 'package:web_app/features/trpg/model/scene_node.dart';

void main() {
  late NodePlayerNotifier player;

  setUp(() {
    player = NodePlayerNotifier();
  });

  tearDown(() {
    player.dispose();
  });

  group('NodePlayerNotifier', () {
    group('initial state', () {
      test('has no current node', () {
        expect(player.currentNode.value, isNull);
      });

      test('is complete', () {
        expect(player.isComplete.value, isTrue);
      });

      test('is not waiting for asset', () {
        expect(player.isWaitingForAsset.value, isFalse);
      });

      test('current index is 0', () {
        expect(player.currentIndex, 0);
      });

      test('node count is 0', () {
        expect(player.nodeCount, 0);
      });
    });

    group('loadNodes', () {
      test('sets the first node as current', () {
        final nodes = [
          const SceneNode(type: 'narration', text: 'Hello world'),
          const SceneNode(type: 'dialogue', text: 'Hi!', speaker: 'NPC'),
        ];
        player.loadNodes(nodes);

        expect(player.currentNode.value, isNotNull);
        expect(player.currentNode.value!.text, 'Hello world');
        expect(player.currentNode.value!.type, 'narration');
      });

      test('marks as not complete when nodes are loaded', () {
        final nodes = [
          const SceneNode(type: 'narration', text: 'Page 1'),
          const SceneNode(type: 'narration', text: 'Page 2'),
        ];
        player.loadNodes(nodes);

        expect(player.isComplete.value, isFalse);
      });

      test('marks as not complete for single node', () {
        final nodes = [const SceneNode(type: 'narration', text: 'Only page')];
        player.loadNodes(nodes);

        expect(player.isComplete.value, isFalse);
        expect(player.currentNode.value!.text, 'Only page');
      });

      test('sets correct node count', () {
        final nodes = [
          const SceneNode(type: 'narration', text: '1'),
          const SceneNode(type: 'narration', text: '2'),
          const SceneNode(type: 'narration', text: '3'),
        ];
        player.loadNodes(nodes);

        expect(player.nodeCount, 3);
      });

      test('resets index to 0', () {
        final nodes = [
          const SceneNode(type: 'narration', text: '1'),
          const SceneNode(type: 'narration', text: '2'),
        ];
        player.loadNodes(nodes);
        player.advance();
        player.loadNodes(nodes);

        expect(player.currentIndex, 0);
        expect(player.currentNode.value!.text, '1');
      });

      test('handles empty list', () {
        player.loadNodes([]);

        expect(player.currentNode.value, isNull);
        expect(player.isComplete.value, isTrue);
        expect(player.nodeCount, 0);
      });
    });

    group('advance', () {
      test('moves to next node', () {
        final nodes = [
          const SceneNode(type: 'narration', text: 'Page 1'),
          const SceneNode(type: 'dialogue', text: 'Page 2', speaker: 'NPC'),
          const SceneNode(type: 'narration', text: 'Page 3'),
        ];
        player.loadNodes(nodes);

        final advanced = player.advance();

        expect(advanced, isTrue);
        expect(player.currentIndex, 1);
        expect(player.currentNode.value!.text, 'Page 2');
        expect(player.currentNode.value!.speaker, 'NPC');
      });

      test('returns false at last node', () {
        final nodes = [const SceneNode(type: 'narration', text: 'Only page')];
        player.loadNodes(nodes);

        final advanced = player.advance();

        expect(advanced, isFalse);
        expect(player.isComplete.value, isTrue);
      });

      test('marks complete when trying to advance past last node', () {
        final nodes = [
          const SceneNode(type: 'narration', text: 'Page 1'),
          const SceneNode(type: 'narration', text: 'Page 2'),
        ];
        player.loadNodes(nodes);

        expect(player.isComplete.value, isFalse);
        player.advance();
        expect(player.isComplete.value, isFalse);

        final advanced = player.advance();
        expect(advanced, isFalse);
        expect(player.isComplete.value, isTrue);
      });

      test('returns false when no nodes loaded', () {
        final advanced = player.advance();
        expect(advanced, isFalse);
      });
    });

    group('asset management', () {
      test('blocks when current node has unresolved background', () {
        final nodes = [
          const SceneNode(
            type: 'narration',
            text: 'Page 1',
            background: 'forest_scene',
          ),
          const SceneNode(type: 'narration', text: 'Page 2'),
        ];
        player.loadNodes(nodes);

        expect(player.isWaitingForAsset.value, isTrue);
      });

      test('does not block when node has no background', () {
        final nodes = [
          const SceneNode(type: 'narration', text: 'No background'),
        ];
        player.loadNodes(nodes);

        expect(player.isWaitingForAsset.value, isFalse);
      });

      test('resolves asset and unblocks', () {
        final nodes = [
          const SceneNode(
            type: 'narration',
            text: 'Forest scene',
            background: 'forest_bg',
          ),
        ];
        player.loadNodes(nodes);

        expect(player.isWaitingForAsset.value, isTrue);

        player.onAssetReady('forest_bg', 'bucket/path/to/forest.png');

        expect(player.isWaitingForAsset.value, isFalse);
      });

      test('advance updates waiting state for next node', () {
        final nodes = [
          const SceneNode(type: 'narration', text: 'Page 1'),
          const SceneNode(
            type: 'narration',
            text: 'Page 2',
            background: 'castle_bg',
          ),
        ];
        player.loadNodes(nodes);

        expect(player.isWaitingForAsset.value, isFalse);

        player.advance();
        expect(player.isWaitingForAsset.value, isTrue);
        expect(player.currentNode.value!.text, 'Page 2');
      });

      test('resolvedAssetUrl returns path for resolved assets', () {
        final nodes = [
          const SceneNode(
            type: 'narration',
            text: 'Scene',
            background: 'bg_key',
          ),
        ];
        player.loadNodes(nodes);

        expect(player.resolvedAssetUrl('bg_key'), isNull);

        player.onAssetReady('bg_key', 'bucket/path.png');
        expect(player.resolvedAssetUrl('bg_key'), 'bucket/path.png');
      });

      test('inherits background from previous node', () {
        final nodes = [
          const SceneNode(
            type: 'narration',
            text: 'Page 1',
            background: 'forest_bg',
          ),
          const SceneNode(type: 'dialogue', text: 'Page 2', speaker: 'NPC'),
        ];
        player.loadNodes(nodes);
        player.onAssetReady('forest_bg', 'bucket/forest.png');

        player.advance();

        expect(player.isWaitingForAsset.value, isFalse);
        expect(player.effectiveBackground, 'forest_bg');
      });
    });

    group('clear', () {
      test('resets all state', () {
        final nodes = [
          const SceneNode(type: 'narration', text: 'Page 1'),
          const SceneNode(type: 'narration', text: 'Page 2'),
        ];
        player.loadNodes(nodes);
        player.advance();

        player.clear();

        expect(player.currentNode.value, isNull);
        expect(player.isComplete.value, isTrue);
        expect(player.isWaitingForAsset.value, isFalse);
        expect(player.currentIndex, 0);
        expect(player.nodeCount, 0);
      });
    });

    group('background inheritance across turns', () {
      test('inherits background from previous turn', () {
        // Turn 1: has background
        final turn1 = [
          const SceneNode(
            type: 'narration',
            text: 'Turn 1',
            background: 'forest_bg',
          ),
        ];
        player.loadNodes(turn1);
        player.onAssetReady('forest_bg', 'bucket/forest.png');

        // Turn 2: no background
        final turn2 = [const SceneNode(type: 'narration', text: 'Turn 2')];
        player.loadNodes(turn2);

        expect(player.effectiveBackground, 'forest_bg');
      });

      test('overrides inherited background with new one', () {
        // Turn 1: forest background
        final turn1 = [
          const SceneNode(
            type: 'narration',
            text: 'Turn 1',
            background: 'forest_bg',
          ),
        ];
        player.loadNodes(turn1);

        // Turn 2: castle background
        final turn2 = [
          const SceneNode(
            type: 'narration',
            text: 'Turn 2',
            background: 'castle_bg',
          ),
        ];
        player.loadNodes(turn2);

        expect(player.effectiveBackground, 'castle_bg');
      });

      test('returns null when both turns have no background', () {
        final turn1 = [const SceneNode(type: 'narration', text: 'Turn 1')];
        player.loadNodes(turn1);

        final turn2 = [const SceneNode(type: 'narration', text: 'Turn 2')];
        player.loadNodes(turn2);

        expect(player.effectiveBackground, isNull);
      });

      test('clear resets inherited background', () {
        // Turn 1: has background
        final turn1 = [
          const SceneNode(
            type: 'narration',
            text: 'Turn 1',
            background: 'forest_bg',
          ),
        ];
        player.loadNodes(turn1);
        player.onAssetReady('forest_bg', 'bucket/forest.png');

        // clear() simulates sendTurn() full reset
        player.clear();

        // Turn 2: no background
        final turn2 = [const SceneNode(type: 'narration', text: 'Turn 2')];
        player.loadNodes(turn2);

        expect(player.effectiveBackground, isNull);
      });

      test('preserves inherited background across multiple loadNodes', () {
        // Turn 1: has background
        final turn1 = [
          const SceneNode(
            type: 'narration',
            text: 'Turn 1',
            background: 'forest_bg',
          ),
        ];
        player.loadNodes(turn1);
        player.onAssetReady('forest_bg', 'bucket/forest.png');

        // Turn 2: no background
        final turn2 = [const SceneNode(type: 'narration', text: 'Turn 2')];
        player.loadNodes(turn2);

        // Turn 3: no background — should still inherit from Turn 1
        final turn3 = [const SceneNode(type: 'narration', text: 'Turn 3')];
        player.loadNodes(turn3);

        expect(player.effectiveBackground, 'forest_bg');
      });

      test('inherited background triggers asset waiting when unresolved', () {
        // Turn 1: has background but NOT resolved
        final turn1 = [
          const SceneNode(
            type: 'narration',
            text: 'Turn 1',
            background: 'forest_bg',
          ),
        ];
        player.loadNodes(turn1);
        // Do NOT call onAssetReady

        // Turn 2: no background — inherits unresolved forest_bg
        final turn2 = [const SceneNode(type: 'narration', text: 'Turn 2')];
        player.loadNodes(turn2);

        expect(player.effectiveBackground, 'forest_bg');
        expect(player.isWaitingForAsset.value, isTrue);

        // Resolve the asset
        player.onAssetReady('forest_bg', 'bucket/forest.png');
        expect(player.isWaitingForAsset.value, isFalse);
      });
    });
  });
}
