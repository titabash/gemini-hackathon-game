import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';

import '../../model/trpg_visual_state.dart';

/// Compact inventory list showing item name, quantity, and equip state.
class InventoryPanelWidget extends StatelessWidget {
  const InventoryPanelWidget({super.key, required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        t.trpg.noItems,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Icon(
                _iconForType(item.itemType),
                color: Colors.white54,
                size: 12,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.quantity > 1)
                Text(
                  'x${item.quantity}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              if (item.isEquipped) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x4444AACC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.trpg.equipped,
                    style: const TextStyle(
                      color: Color(0xFF88CCEE),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  static IconData _iconForType(String itemType) {
    return switch (itemType) {
      'weapon' => Icons.gavel,
      'armor' => Icons.shield,
      'consumable' => Icons.local_drink,
      'key' => Icons.vpn_key,
      _ => Icons.inventory_2_outlined,
    };
  }
}
