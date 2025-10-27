import 'package:flutter/material.dart';
import '../state/inventory.dart';

class InventoryPanel extends StatelessWidget {
  final VoidCallback onClose;
  final int columns;

  const InventoryPanel({
    super.key,
    required this.onClose,
    this.columns = 5,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final spacing = 8.0;
    final gridPadding = 12.0;
    final panelWidth = size.width * 0.4;
    // Cap panel height to 90% of screen to avoid overflow. Grid inside will scroll if needed.
    final panelHeight = (size.height * 0.9).floorToDouble();

    return Material(
      color: Colors.white.withOpacity(0.98),
      borderRadius: BorderRadius.circular(12),
      elevation: 6,
      child: SizedBox(
        width: panelWidth,
        height: panelHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, size: 18),
                  const SizedBox(width: 6),
                  const Text('Hành trang', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            // Grid area takes remaining space and scrolls if overflowing
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: AnimatedBuilder(
                  animation: Inventory.instance,
                  builder: (context, _) {
                    final items = Inventory.instance.items;
                    final totalSlots = Inventory.instance.capacity;
                    return GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1,
                      ),
                      itemCount: totalSlots,
                      itemBuilder: (context, index) {
                        final item = index < items.length ? items[index] : null;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black26),
                          ),
                          child: item == null
                              ? const SizedBox.shrink()
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Image.asset(
                                          item.imageAssetPath,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
