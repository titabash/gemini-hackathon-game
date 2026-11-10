import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:core_genui/catalog/game_catalog_items.dart';
import 'package:core_genui/widgets/genui_surface_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders game surfaces from the A2UI v0.9 messages the GM backend sends
/// (see `genui_bridge_service.py`).
void main() {
  late MessageProcessor<ComponentImplementation> processor;
  late List<A2uiRendererAction> actions;
  late List<A2uiRendererError> errors;

  setUp(() {
    processor = MessageProcessor<ComponentImplementation>(
      catalogs: [GameCatalogItems.asCatalog()],
      validationConfig: ValidationConfig.strict,
    );
    actions = [];
    errors = [];
    processor.model.onAction.subscribe(actions.add);
    processor.model.onError.subscribe(errors.add);
  });

  tearDown(() => processor.dispose());

  void showSurface(String surfaceId, Map<String, Object?> root) {
    processor.processMessages([
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': surfaceId,
          'catalogId': GameCatalogItems.catalogId,
        },
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': [
            {'id': 'root', ...root},
          ],
        },
      },
    ]);
  }

  Future<void> pump(WidgetTester tester, String surfaceId) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GenuiSurfaceView(
              processor: processor,
              surfaceId: surfaceId,
              defaultBuilder: (_) => const Text('no surface'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('choiceGroup sends the chosen text as a choice action', (
    tester,
  ) async {
    await pump(tester, 'game-surface');
    expect(find.text('no surface'), findsOneWidget);

    showSurface('game-surface', {
      'component': 'choiceGroup',
      'choices': [
        {'id': 'c1', 'text': 'Open the door', 'hint': null},
        {'id': 'c2', 'text': 'Walk away', 'hint': 'Safe'},
      ],
      'allowFreeInput': true,
    });
    await tester.pump();

    expect(find.text('Open the door'), findsOneWidget);
    await tester.tap(find.text('Walk away'));
    await tester.pump();

    expect(actions, hasLength(1));
    expect(actions.single.name, 'choice');
    expect(actions.single.surfaceId, 'game-surface');
    expect(actions.single.context, {
      'inputType': 'choice',
      'inputText': 'Walk away',
    });
    expect(errors, isEmpty);
  });

  testWidgets('narrativePanel renders sections and is removed on delete', (
    tester,
  ) async {
    showSurface('game-narration', {
      'component': 'narrativePanel',
      'sections': [
        {'type': 'dialogue', 'speaker': 'Guard', 'text': 'Halt!'},
        {'type': 'narration', 'text': 'The gate is closed.'},
      ],
    });
    await pump(tester, 'game-narration');

    expect(find.textContaining('Halt!'), findsOneWidget);

    processor.processMessages({
      'version': 'v0.9',
      'deleteSurface': {'surfaceId': 'game-narration'},
    });
    await tester.pump();

    expect(find.textContaining('Halt!'), findsNothing);
    expect(find.text('no surface'), findsOneWidget);
    expect(errors, isEmpty);
  });

  test('npcGallery accepts NPCs without an image', () {
    showSurface('game-npcs', {
      'component': 'npcGallery',
      'npcs': [
        {'name': 'Guard', 'emotion': null, 'imagePath': null},
      ],
      'speakers': ['Guard'],
    });

    expect(processor.model.getSurface('game-npcs'), isNotNull);
    expect(errors, isEmpty);
  });
}
