// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' show ComponentNode;
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/v0_9/basic_catalog.dart' as v0_9;
import 'package:core_i18n/generated/strings.g.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:shared_ui/vn/vn.dart';

/// Game-specific catalog items for VN-style TRPG UI.
///
/// These items render as VN-style widgets using the shared_ui VN components.
/// User interactions are dispatched as A2UI actions through the surface,
/// and reach the processor's `model.onAction`.
class GameCatalogItems {
  const GameCatalogItems._();

  /// The catalog ID the GM backend sends in `createSurface`.
  ///
  /// Must match `GAME_CATALOG_ID` in
  /// `backend-py/app/src/domain/service/genui_bridge_service.py`.
  static const catalogId =
      'https://github.com/titabash/gemini-hackathon-game/catalogs/game_catalog.json';

  /// Returns a [CatalogImplementation] with basic + game-specific items.
  ///
  /// Starts from the A2UI v0.9 basic catalog and extends it with
  /// game-specific VN widgets under [catalogId].
  /// [resolveImageUrl] converts a raw storage path (e.g.
  /// `scenario-assets/npcs/wizard.png`) into a full URL via
  /// `supabase.storage.from(bucket).getPublicUrl(objectPath)`.
  static CatalogImplementation asCatalog({
    String Function(String storagePath)? resolveImageUrl,
  }) {
    return v0_9.basicCatalog().derive(
      catalogId: catalogId,
      addComponents: [
        _novelTextBoxItem(),
        _narrativePanelItem(),
        _processingIndicatorItem(),
        _npcGalleryItem(resolveImageUrl: resolveImageUrl),
        _choiceGroupItem(),
        _actionInputItem(),
        _clarifyQuestionItem(),
        _repairConfirmItem(),
        _continueOrInputItem(),
        _continueButtonItem(),
        _textInputItem(),
      ],
    );
  }

  /// Sends a user action from [node], as genui's `dispatchEvent` did.
  static void _dispatch(
    ComponentNode<ComponentImplementation> node,
    String name, [
    Map<String, Object?> context = const {},
  ]) {
    unawaited(
      node.context?.dispatchAction({
        'event': {'name': name, 'context': context},
      }),
    );
  }

  /// The map entries of a list property.
  static Iterable<Map<Object?, Object?>> _maps(List<Object?> list) =>
      list.whereType<Map<Object?, Object?>>();

  // -- novelTextBox ----------------------------------------------------------

  static ComponentImplementation _novelTextBoxItem() {
    return ComponentImplementation(
      name: 'novelTextBox',
      schema: S.object(
        properties: {
          'text': S.string(),
          'speaker': S.string(),
          'showNextIndicator': S.boolean(),
        },
      ),
      builder: (context, node, props, buildChild) {
        return VnTextBox(
          text: props.string('text') ?? '',
          speaker: props.string('speaker'),
          showNextIndicator: props.boolean('showNextIndicator') ?? false,
          onAdvance: () => _dispatch(node, 'advance'),
        );
      },
    );
  }

  // -- narrativePanel --------------------------------------------------------

  static ComponentImplementation _narrativePanelItem() {
    return ComponentImplementation(
      name: 'narrativePanel',
      schema: S.object(
        properties: {'sections': S.list(items: S.object(properties: {}))},
      ),
      builder: (context, node, props, buildChild) {
        final sections = props.list('sections');
        return VnNarrativePanel(
          sections: _maps(sections).map((s) {
            return VnNarrativeSection(
              type: s['type'] as String? ?? 'narration',
              speaker: s['speaker'] as String?,
              text: s['text'] as String? ?? '',
            );
          }).toList(),
          onAdvance: () => _dispatch(node, 'advance'),
        );
      },
    );
  }

  // -- processingIndicator ---------------------------------------------------

  static ComponentImplementation _processingIndicatorItem() {
    return ComponentImplementation(
      name: 'processingIndicator',
      schema: S.object(properties: {}),
      builder: (context, node, props, buildChild) {
        return const VnTextBox(text: '', isProcessing: true, onAdvance: _noop);
      },
    );
  }

  // -- npcGallery ------------------------------------------------------------

  static ComponentImplementation _npcGalleryItem({
    String Function(String storagePath)? resolveImageUrl,
  }) {
    return ComponentImplementation(
      name: 'npcGallery',
      schema: S.object(
        properties: {
          'npcs': S.list(items: S.object(properties: {})),
          'speakers': S.list(items: S.string()),
        },
      ),
      builder: (context, node, props, buildChild) {
        final npcs = props.list('npcs');
        final speakers = props.list('speakers').whereType<String>().toList();
        return VnNpcGallery(
          npcs: _maps(npcs).map((n) {
            final rawPath = n['imagePath'] as String?;
            final imageUrl = rawPath != null && resolveImageUrl != null
                ? resolveImageUrl(rawPath)
                : rawPath;
            return VnNpcData(
              name: n['name'] as String? ?? '',
              emotion: n['emotion'] as String?,
              imagePath: imageUrl,
            );
          }).toList(),
          speakers: speakers,
        );
      },
    );
  }

  // -- choiceGroup -----------------------------------------------------------

  static ComponentImplementation _choiceGroupItem() {
    return ComponentImplementation(
      name: 'choiceGroup',
      schema: S.object(
        properties: {
          'choices': S.list(items: S.object(properties: {})),
          'allowFreeInput': S.boolean(),
        },
      ),
      builder: (context, node, props, buildChild) {
        final choices = props.list('choices');

        return VnOverlayContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.trpg.chooseAction,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._maps(choices).map((c) {
                final text = c['text'] as String? ?? '';
                final hint = c['hint'] as String?;
                return VnChoiceButton(
                  text: text,
                  hint: hint,
                  onPressed: () {
                    Logger.info(
                      'choiceGroup: onPressed fired, '
                      'text=$text, componentId=${node.componentId}',
                    );
                    _dispatch(node, 'choice', {
                      'inputType': 'choice',
                      'inputText': text,
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // -- actionInput -----------------------------------------------------------

  static ComponentImplementation _actionInputItem() {
    return ComponentImplementation(
      name: 'actionInput',
      schema: S.object(properties: {'question': S.string()}),
      builder: (context, node, props, buildChild) {
        final question = props.string('question') ?? '';

        return VnOverlayContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _VnTextInput(
                hint: t.trpg.inputHint,
                onSubmit: (text) => _dispatch(node, 'textInput', {
                  'inputType': 'do',
                  'inputText': text,
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // -- clarifyQuestion -------------------------------------------------------

  static ComponentImplementation _clarifyQuestionItem() {
    return ComponentImplementation(
      name: 'clarifyQuestion',
      schema: S.object(properties: {'question': S.string()}),
      builder: (context, node, props, buildChild) {
        final question = props.string('question') ?? '';

        return VnOverlayContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.help_outline,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.trpg.clarifyTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _VnTextInput(
                hint: t.trpg.clarifyHint,
                onSubmit: (text) => _dispatch(node, 'clarifyAnswer', {
                  'inputType': 'clarify_answer',
                  'inputText': text,
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // -- repairConfirm ---------------------------------------------------------

  static ComponentImplementation _repairConfirmItem() {
    return ComponentImplementation(
      name: 'repairConfirm',
      schema: S.object(
        properties: {'contradiction': S.string(), 'proposed_fix': S.string()},
      ),
      builder: (context, node, props, buildChild) {
        final contradiction = props.string('contradiction') ?? '';
        final proposedFix = props.string('proposed_fix') ?? '';

        return VnOverlayContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.trpg.repairTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.trpg.repairContradiction(text: contradiction),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                t.trpg.repairFix(text: proposedFix),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VnChoiceButton(
                    text: t.trpg.repairReject,
                    onPressed: () => _dispatch(node, 'reject', {
                      'inputType': 'clarify_answer',
                      'inputText': 'reject',
                    }),
                  ),
                  const SizedBox(width: 8),
                  VnChoiceButton(
                    text: t.trpg.repairAccept,
                    onPressed: () => _dispatch(node, 'accept', {
                      'inputType': 'clarify_answer',
                      'inputText': 'accept',
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // -- continueButton --------------------------------------------------------

  static ComponentImplementation _continueOrInputItem() {
    return ComponentImplementation(
      name: 'continueOrInput',
      schema: S.object(properties: {'hint': S.string()}),
      builder: (context, node, props, buildChild) {
        final hint = props.string('hint') ?? t.trpg.inputHint;

        return VnOverlayContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: VnChoiceButton(
                  text: t.trpg.continueButton,
                  onPressed: () => _dispatch(node, 'continue', {
                    'inputType': 'do',
                    'inputText': 'continue',
                  }),
                ),
              ),
              const SizedBox(height: 12),
              _VnTextInput(
                hint: hint,
                onSubmit: (text) => _dispatch(node, 'textInput', {
                  'inputType': 'do',
                  'inputText': text,
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // -- continueButton --------------------------------------------------------

  static ComponentImplementation _continueButtonItem() {
    return ComponentImplementation(
      name: 'continueButton',
      schema: S.object(properties: {}),
      builder: (context, node, props, buildChild) {
        return VnOverlayContainer(
          child: Center(
            child: VnChoiceButton(
              text: t.trpg.continueButton,
              onPressed: () => _dispatch(node, 'continue', {
                'inputType': 'do',
                'inputText': 'continue',
              }),
            ),
          ),
        );
      },
    );
  }

  // -- textInput -------------------------------------------------------------

  static ComponentImplementation _textInputItem() {
    return ComponentImplementation(
      name: 'textInput',
      schema: S.object(properties: {'hint': S.string()}),
      builder: (context, node, props, buildChild) {
        final hint = props.string('hint') ?? t.trpg.inputHint;

        return VnOverlayContainer(
          child: _VnTextInput(
            hint: hint,
            onSubmit: (text) => _dispatch(node, 'textInput', {
              'inputType': 'do',
              'inputText': text,
            }),
          ),
        );
      },
    );
  }

  static void _noop() {}
}

/// Stateful text input widget for VN-style UI.
class _VnTextInput extends StatefulWidget {
  const _VnTextInput({required this.hint, required this.onSubmit});

  final String hint;
  final void Function(String text) onSubmit;

  @override
  State<_VnTextInput> createState() => _VnTextInputState();
}

class _VnTextInputState extends State<_VnTextInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onSubmitted: (_) => _submit(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        suffixIcon: IconButton(
          icon: const Icon(Icons.send, color: Colors.white54),
          onPressed: _submit,
        ),
      ),
    );
  }
}
