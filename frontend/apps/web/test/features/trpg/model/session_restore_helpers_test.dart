import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/features/trpg/model/scene_node.dart';
import 'package:web_app/features/trpg/model/session_restore_helpers.dart';

void main() {
  group('buildBackgroundAssetMap', () {
    String resolveUrl(String path) => 'https://cdn.example.com/$path';

    test('scenario_id あり → scenario-assets/{image_path} で解決', () {
      final rows = [
        {
          'id': 'bg-uuid-1',
          'scenario_id': 'sc-uuid-1',
          'session_id': null,
          'image_path': 'backgrounds/forest.png',
          'description': 'A dark forest',
        },
      ];

      final result = buildBackgroundAssetMap(rows, resolveUrl);

      const expectedUrl =
          'https://cdn.example.com/scenario-assets/backgrounds/forest.png';
      expect(result['bg-uuid-1'], expectedUrl);
      expect(result['A dark forest'], expectedUrl);
    });

    test('scenario_id なし → generated-images/{image_path} で解決', () {
      final rows = [
        {
          'id': 'bg-uuid-2',
          'scenario_id': null,
          'session_id': 'sess-uuid-1',
          'image_path': 'sessions/abc/bg.png',
          'description': 'A mountain view',
        },
      ];

      final result = buildBackgroundAssetMap(rows, resolveUrl);

      const expectedUrl =
          'https://cdn.example.com/generated-images/sessions/abc/bg.png';
      expect(result['bg-uuid-2'], expectedUrl);
      expect(result['A mountain view'], expectedUrl);
    });

    test('id と description 両方でマップ登録', () {
      final rows = [
        {
          'id': 'bg-uuid-3',
          'scenario_id': 'sc-uuid-1',
          'session_id': null,
          'image_path': 'backgrounds/castle.png',
          'description': 'A grand castle',
        },
      ];

      final result = buildBackgroundAssetMap(rows, resolveUrl);

      expect(result.containsKey('bg-uuid-3'), isTrue);
      expect(result.containsKey('A grand castle'), isTrue);
      expect(result['bg-uuid-3'], result['A grand castle']);
    });

    test('image_path が null → スキップ', () {
      final rows = [
        {
          'id': 'bg-uuid-4',
          'scenario_id': 'sc-uuid-1',
          'session_id': null,
          'image_path': null,
          'description': 'No image',
        },
      ];

      final result = buildBackgroundAssetMap(rows, resolveUrl);
      expect(result, isEmpty);
    });

    test('image_path が空文字列 → スキップ', () {
      final rows = [
        {
          'id': 'bg-uuid-5',
          'scenario_id': 'sc-uuid-1',
          'session_id': null,
          'image_path': '',
          'description': 'Empty path',
        },
      ];

      final result = buildBackgroundAssetMap(rows, resolveUrl);
      expect(result, isEmpty);
    });

    test('複数行を正しく処理', () {
      final rows = [
        {
          'id': 'bg-1',
          'scenario_id': 'sc-1',
          'session_id': null,
          'image_path': 'bg/a.png',
          'description': 'Forest',
        },
        {
          'id': 'bg-2',
          'scenario_id': null,
          'session_id': 'sess-1',
          'image_path': 'bg/b.png',
          'description': 'Mountain',
        },
      ];

      final result = buildBackgroundAssetMap(rows, resolveUrl);
      expect(result.length, 4); // 2 rows × 2 keys (id + description)
      expect(
        result['bg-1'],
        'https://cdn.example.com/scenario-assets/bg/a.png',
      );
      expect(
        result['bg-2'],
        'https://cdn.example.com/generated-images/bg/b.png',
      );
    });
  });

  group('buildNpcAssetMap', () {
    String resolveUrl(String path) => 'https://cdn.example.com/$path';

    test('デフォルト画像 + 感情画像のマップ構築', () {
      final rows = [
        {
          'name': 'Wizard',
          'image_path': 'npcs/wizard.png',
          'emotion_images': {
            'joy': 'npcs/wizard_joy.png',
            'anger': 'npcs/wizard_anger.png',
          },
        },
      ];

      final result = buildNpcAssetMap(rows, resolveUrl);

      expect(result.containsKey('Wizard'), isTrue);
      final wizard = result['Wizard']!;
      expect(
        wizard.defaultUrl,
        'https://cdn.example.com/scenario-assets/npcs/wizard.png',
      );
      expect(
        wizard.emotionUrls['joy'],
        'https://cdn.example.com/scenario-assets/npcs/wizard_joy.png',
      );
      expect(
        wizard.emotionUrls['anger'],
        'https://cdn.example.com/scenario-assets/npcs/wizard_anger.png',
      );
    });

    test('image_path なし → defaultUrl は null', () {
      final rows = [
        {
          'name': 'Ghost',
          'image_path': null,
          'emotion_images': {'joy': 'npcs/ghost_joy.png'},
        },
      ];

      final result = buildNpcAssetMap(rows, resolveUrl);

      expect(result['Ghost']!.defaultUrl, isNull);
      expect(
        result['Ghost']!.emotionUrls['joy'],
        'https://cdn.example.com/scenario-assets/npcs/ghost_joy.png',
      );
    });

    test('emotion_images なし → 空マップ', () {
      final rows = [
        {
          'name': 'Knight',
          'image_path': 'npcs/knight.png',
          'emotion_images': null,
        },
      ];

      final result = buildNpcAssetMap(rows, resolveUrl);

      expect(result['Knight']!.emotionUrls, isEmpty);
      expect(
        result['Knight']!.defaultUrl,
        'https://cdn.example.com/scenario-assets/npcs/knight.png',
      );
    });

    test('複数NPC', () {
      final rows = [
        {'name': 'A', 'image_path': 'npcs/a.png', 'emotion_images': null},
        {
          'name': 'B',
          'image_path': 'npcs/b.png',
          'emotion_images': {'joy': 'npcs/b_joy.png'},
        },
      ];

      final result = buildNpcAssetMap(rows, resolveUrl);

      expect(result.length, 2);
      expect(result.containsKey('A'), isTrue);
      expect(result.containsKey('B'), isTrue);
    });
  });

  group('findEffectiveBackground', () {
    test('指定インデックスから後方探索して最初のbackgroundを返す', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a', background: 'bg-1'),
        const SceneNode(type: 'dialogue', text: 'b'),
        const SceneNode(type: 'narration', text: 'c', background: 'bg-2'),
        const SceneNode(type: 'dialogue', text: 'd'),
      ];

      expect(findEffectiveBackground(nodes, 3), 'bg-2');
      expect(findEffectiveBackground(nodes, 2), 'bg-2');
      expect(findEffectiveBackground(nodes, 1), 'bg-1');
      expect(findEffectiveBackground(nodes, 0), 'bg-1');
    });

    test('全ノード background なし → null', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a'),
        const SceneNode(type: 'dialogue', text: 'b'),
      ];

      expect(findEffectiveBackground(nodes, 1), isNull);
    });

    test('空のノードリスト → null', () {
      expect(findEffectiveBackground([], 0), isNull);
    });

    test('fromIndex がリスト範囲外 → リスト末尾からクランプして探索', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a', background: 'bg-1'),
      ];

      expect(findEffectiveBackground(nodes, 5), 'bg-1');
    });
  });

  group('normalizeMood', () {
    test('通常の文字列 → trim + lowercase', () {
      expect(normalizeMood('  Tense '), 'tense');
    });

    test('null → null', () {
      expect(normalizeMood(null), isNull);
    });

    test('空文字列 → null', () {
      expect(normalizeMood(''), isNull);
    });

    test('空白のみ → null', () {
      expect(normalizeMood('   '), isNull);
    });

    test('既に小文字 → そのまま', () {
      expect(normalizeMood('calm'), 'calm');
    });

    test('大文字混在 → lowercase', () {
      expect(normalizeMood('BATTLE'), 'battle');
    });
  });

  group('resolveNodeBgmMoodAtIndex', () {
    test('bgm が後のノードにのみある場合、index 0 では null', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a'),
        const SceneNode(type: 'dialogue', text: 'b', bgm: 'tense'),
      ];

      expect(resolveNodeBgmMoodAtIndex(nodes, 0), isNull);
    });

    test('bgm が後のノードにある場合、そのインデックスでは mood を返す', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a'),
        const SceneNode(type: 'dialogue', text: 'b', bgm: 'tense'),
      ];

      expect(resolveNodeBgmMoodAtIndex(nodes, 1), 'tense');
    });

    test('bgm が現在ノードにある場合、mood を返す', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a', bgm: 'calm'),
        const SceneNode(type: 'dialogue', text: 'b'),
      ];

      expect(resolveNodeBgmMoodAtIndex(nodes, 0), 'calm');
      // index 1 でも先行ノードの bgm が有効
      expect(resolveNodeBgmMoodAtIndex(nodes, 1), 'calm');
    });

    test('bgmStop 後は null を返す', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a', bgm: 'calm'),
        const SceneNode(type: 'dialogue', text: 'b', bgmStop: true),
        const SceneNode(type: 'narration', text: 'c'),
      ];

      expect(resolveNodeBgmMoodAtIndex(nodes, 0), 'calm');
      expect(resolveNodeBgmMoodAtIndex(nodes, 1), isNull);
      expect(resolveNodeBgmMoodAtIndex(nodes, 2), isNull);
    });

    test('bgmStop 後に新しい bgm で再開する', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a', bgm: 'calm'),
        const SceneNode(type: 'dialogue', text: 'b', bgmStop: true),
        const SceneNode(type: 'narration', text: 'c', bgm: 'battle'),
      ];

      expect(resolveNodeBgmMoodAtIndex(nodes, 0), 'calm');
      expect(resolveNodeBgmMoodAtIndex(nodes, 1), isNull);
      expect(resolveNodeBgmMoodAtIndex(nodes, 2), 'battle');
    });

    test('空リスト → null', () {
      expect(resolveNodeBgmMoodAtIndex([], 0), isNull);
    });

    test('範囲外インデックス → リスト末尾にクランプ', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a', bgm: 'calm'),
      ];

      expect(resolveNodeBgmMoodAtIndex(nodes, 10), 'calm');
    });

    test('bgm の大文字小文字・空白は正規化される', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'a', bgm: '  TENSE  '),
      ];

      expect(resolveNodeBgmMoodAtIndex(nodes, 0), 'tense');
    });
  });

  group('buildNodesSummary', () {
    test('ナレーション + ダイアログの要約テキスト構築', () {
      final nodes = [
        const SceneNode(type: 'narration', text: 'The sun sets.'),
        const SceneNode(
          type: 'dialogue',
          text: 'Hello there!',
          speaker: 'Wizard',
        ),
        const SceneNode(type: 'narration', text: 'Silence follows.'),
      ];

      final result = buildNodesSummary(nodes);

      expect(result, contains('The sun sets.'));
      expect(result, contains('[Wizard] Hello there!'));
      expect(result, contains('Silence follows.'));
    });

    test('空のノードリスト → 空文字列', () {
      expect(buildNodesSummary([]), isEmpty);
    });

    test('speaker なし → テキストのみ', () {
      final nodes = [const SceneNode(type: 'narration', text: 'Just text.')];

      final result = buildNodesSummary(nodes);
      expect(result, 'Just text.');
    });
  });
}
