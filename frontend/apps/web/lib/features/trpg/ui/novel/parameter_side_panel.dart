import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';
import 'inventory_panel_widget.dart';
import 'objectives_panel_widget.dart';
import 'relationships_panel_widget.dart';
import 'stat_bar_widget.dart';
import 'status_effects_widget.dart';

/// Expandable side panel showing all TRPG character parameters.
class ParameterSidePanel extends StatelessWidget {
  const ParameterSidePanel({
    super.key,
    required this.visualState,
    required this.onClose,
  });

  final TrpgVisualState visualState;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xDD1A1A2E),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.trpg.parameterPanel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats section
                  if (visualState.stats.isNotEmpty) ...[
                    _SectionHeader(title: t.trpg.stats),
                    const SizedBox(height: 4),
                    ...visualState.stats.entries.map((entry) {
                      final maxKey = 'max_${entry.key}';
                      final maxVal = visualState.maxStats[maxKey];
                      return StatBarWidget(
                        label: entry.key,
                        value: entry.value,
                        maxValue: maxVal,
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // Status effects
                  if (visualState.statusEffects.isNotEmpty) ...[
                    StatusEffectsWidget(effects: visualState.statusEffects),
                    const SizedBox(height: 12),
                  ],

                  // Inventory
                  _SectionHeader(title: t.trpg.inventory),
                  const SizedBox(height: 4),
                  InventoryPanelWidget(items: visualState.items),
                  const SizedBox(height: 12),

                  // Objectives
                  _SectionHeader(title: t.trpg.objectives),
                  const SizedBox(height: 4),
                  ObjectivesPanelWidget(objectives: visualState.objectives),
                  const SizedBox(height: 12),

                  // Relationships
                  if (visualState.relationships.isNotEmpty) ...[
                    _SectionHeader(title: t.trpg.relationships),
                    const SizedBox(height: 4),
                    RelationshipsPanelWidget(
                      relationships: visualState.relationships,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}
