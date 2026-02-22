// ignore_for_file: avoid_dynamic_calls

import 'dart:math';

import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:shared_ui/vn/vn.dart';

/// Game-specific catalog items for VN-style TRPG UI.
///
/// These items render as VN-style widgets using the shared_ui VN components.
/// User interactions are dispatched as [UserActionEvent] via genui's
/// event system.
class GameCatalogItems {
  const GameCatalogItems._();

  /// Returns a [Catalog] with core + game-specific items.
  ///
  /// Starts from [CoreCatalogItems] (which provides the standard catalog with
  /// ID `a2ui.org:standard_catalog_0_8_0`) and extends it with game-specific
  /// VN widgets.
  /// [resolveImageUrl] converts a raw storage path (e.g.
  /// `scenario-assets/npcs/wizard.png`) into a full URL via
  /// `supabase.storage.from(bucket).getPublicUrl(objectPath)`.
  static Catalog asCatalog({
    String Function(String storagePath)? resolveImageUrl,
  }) {
    final coreCatalog = CoreCatalogItems.asCatalog();
    return coreCatalog.copyWith([
      _novelTextBoxItem(),
      _narrativePanelItem(),
      _processingIndicatorItem(),
      _npcGalleryItem(resolveImageUrl: resolveImageUrl),
      _choiceGroupItem(),
      _rollPanelItem(),
      _clarifyQuestionItem(),
      _repairConfirmItem(),
      _continueButtonItem(),
      _textInputItem(),
    ]);
  }

  // -- novelTextBox ----------------------------------------------------------

  static CatalogItem _novelTextBoxItem() {
    return CatalogItem(
      name: 'novelTextBox',
      dataSchema: S.object(
        properties: {
          'text': S.string(),
          'speaker': S.string(),
          'showNextIndicator': S.boolean(),
        },
      ),
      widgetBuilder: (ctx) {
        final data = ctx.data;
        if (data is! Map<String, dynamic>) return const SizedBox.shrink();
        return VnTextBox(
          text: data['text'] as String? ?? '',
          speaker: data['speaker'] as String?,
          showNextIndicator: data['showNextIndicator'] as bool? ?? false,
          onAdvance: () => ctx.dispatchEvent(
            UserActionEvent(name: 'advance', sourceComponentId: ctx.id),
          ),
        );
      },
    );
  }

  // -- narrativePanel --------------------------------------------------------

  static CatalogItem _narrativePanelItem() {
    return CatalogItem(
      name: 'narrativePanel',
      dataSchema: S.object(
        properties: {'sections': S.list(items: S.object(properties: {}))},
      ),
      widgetBuilder: (ctx) {
        final data = ctx.data;
        if (data is! Map<String, dynamic>) return const SizedBox.shrink();
        final sections = (data['sections'] as List<dynamic>?) ?? [];
        return VnNarrativePanel(
          sections: sections.cast<Map<String, dynamic>>().map((s) {
            return VnNarrativeSection(
              type: s['type'] as String? ?? 'narration',
              speaker: s['speaker'] as String?,
              text: s['text'] as String? ?? '',
            );
          }).toList(),
          onAdvance: () => ctx.dispatchEvent(
            UserActionEvent(name: 'advance', sourceComponentId: ctx.id),
          ),
        );
      },
    );
  }

  // -- processingIndicator ---------------------------------------------------

  static CatalogItem _processingIndicatorItem() {
    return CatalogItem(
      name: 'processingIndicator',
      dataSchema: S.object(properties: {}),
      widgetBuilder: (ctx) {
        return const VnTextBox(text: '', isProcessing: true, onAdvance: _noop);
      },
    );
  }

  // -- npcGallery ------------------------------------------------------------

  static CatalogItem _npcGalleryItem({
    String Function(String storagePath)? resolveImageUrl,
  }) {
    return CatalogItem(
      name: 'npcGallery',
      dataSchema: S.object(
        properties: {
          'npcs': S.list(items: S.object(properties: {})),
          'speakers': S.list(items: S.string()),
        },
      ),
      widgetBuilder: (ctx) {
        final data = ctx.data;
        if (data is! Map<String, dynamic>) return const SizedBox.shrink();
        final npcs = (data['npcs'] as List<dynamic>?) ?? [];
        final speakers =
            (data['speakers'] as List<dynamic>?)?.cast<String>() ?? [];
        return VnNpcGallery(
          npcs: npcs.cast<Map<String, dynamic>>().map((n) {
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

  static CatalogItem _choiceGroupItem() {
    return CatalogItem(
      name: 'choiceGroup',
      dataSchema: S.object(
        properties: {
          'choices': S.list(items: S.object(properties: {})),
          'allowFreeInput': S.boolean(),
        },
      ),
      widgetBuilder: (ctx) {
        final data = ctx.data;
        if (data is! Map<String, dynamic>) return const SizedBox.shrink();
        final choices = (data['choices'] as List<dynamic>?) ?? [];

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
              ...choices.map((choice) {
                final c = choice as Map<String, dynamic>;
                final text = c['text'] as String? ?? '';
                final hint = c['hint'] as String?;
                return VnChoiceButton(
                  text: text,
                  hint: hint,
                  onPressed: () => ctx.dispatchEvent(
                    UserActionEvent(
                      name: 'choice',
                      sourceComponentId: ctx.id,
                      context: {'inputType': 'choice', 'inputText': text},
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // -- rollPanel -------------------------------------------------------------

  static CatalogItem _rollPanelItem() {
    return CatalogItem(
      name: 'rollPanel',
      dataSchema: S.object(
        properties: {
          'skill_name': S.string(),
          'difficulty': S.integer(),
          'stakes_success': S.string(),
          'stakes_failure': S.string(),
        },
      ),
      widgetBuilder: (ctx) {
        final data = ctx.data;
        if (data is! Map<String, dynamic>) return const SizedBox.shrink();
        final skillName = data['skill_name'] as String? ?? '';
        final difficulty = data['difficulty'] as int? ?? 0;
        final stakesSuccess = data['stakes_success'] as String? ?? '';
        final stakesFailure = data['stakes_failure'] as String? ?? '';

        return VnOverlayContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.casino, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${t.trpg.rollCheck}: $skillName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.trpg.rollDifficulty(n: difficulty),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                t.trpg.rollSuccess(text: stakesSuccess),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                t.trpg.rollFailure(text: stakesFailure),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Center(
                child: VnChoiceButton(
                  text: t.trpg.rollButton,
                  onPressed: () {
                    final result = Random().nextInt(20) + 1;
                    ctx.dispatchEvent(
                      UserActionEvent(
                        name: 'roll',
                        sourceComponentId: ctx.id,
                        context: {
                          'inputType': 'roll_result',
                          'inputText': result.toString(),
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -- clarifyQuestion -------------------------------------------------------

  static CatalogItem _clarifyQuestionItem() {
    return CatalogItem(
      name: 'clarifyQuestion',
      dataSchema: S.object(properties: {'question': S.string()}),
      widgetBuilder: (ctx) {
        final data = ctx.data;
        if (data is! Map<String, dynamic>) return const SizedBox.shrink();
        final question = data['question'] as String? ?? '';

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
            ],
          ),
        );
      },
    );
  }

  // -- repairConfirm ---------------------------------------------------------

  static CatalogItem _repairConfirmItem() {
    return CatalogItem(
      name: 'repairConfirm',
      dataSchema: S.object(
        properties: {'contradiction': S.string(), 'proposed_fix': S.string()},
      ),
      widgetBuilder: (ctx) {
        final data = ctx.data;
        if (data is! Map<String, dynamic>) return const SizedBox.shrink();
        final contradiction = data['contradiction'] as String? ?? '';
        final proposedFix = data['proposed_fix'] as String? ?? '';

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
                    onPressed: () => ctx.dispatchEvent(
                      UserActionEvent(
                        name: 'reject',
                        sourceComponentId: ctx.id,
                        context: {
                          'inputType': 'clarify_answer',
                          'inputText': 'reject',
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  VnChoiceButton(
                    text: t.trpg.repairAccept,
                    onPressed: () => ctx.dispatchEvent(
                      UserActionEvent(
                        name: 'accept',
                        sourceComponentId: ctx.id,
                        context: {
                          'inputType': 'clarify_answer',
                          'inputText': 'accept',
                        },
                      ),
                    ),
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

  static CatalogItem _continueButtonItem() {
    return CatalogItem(
      name: 'continueButton',
      dataSchema: S.object(properties: {}),
      widgetBuilder: (ctx) {
        return VnOverlayContainer(
          child: Center(
            child: VnChoiceButton(
              text: t.trpg.continueButton,
              onPressed: () => ctx.dispatchEvent(
                UserActionEvent(
                  name: 'continue',
                  sourceComponentId: ctx.id,
                  context: {'inputType': 'do', 'inputText': 'continue'},
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -- textInput -------------------------------------------------------------

  static CatalogItem _textInputItem() {
    return CatalogItem(
      name: 'textInput',
      dataSchema: S.object(properties: {'hint': S.string()}),
      widgetBuilder: (ctx) {
        final data = ctx.data;
        if (data is! Map<String, dynamic>) return const SizedBox.shrink();
        final hint = data['hint'] as String? ?? t.trpg.inputHint;

        return VnOverlayContainer(
          child: _VnTextInput(
            hint: hint,
            onSubmit: (text) => ctx.dispatchEvent(
              UserActionEvent(
                name: 'textInput',
                sourceComponentId: ctx.id,
                context: {'inputType': 'do', 'inputText': text},
              ),
            ),
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
