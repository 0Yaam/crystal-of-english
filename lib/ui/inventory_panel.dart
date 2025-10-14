import 'package:flutter/material.dart';
import '../state/inventory.dart';

class InventoryPanel extends StatelessWidget {
  final VoidCallback onClose;
  final int totalSlots;
  final int columns;

  const InventoryPanel({
    super.key,
    required this.onClose,
    this.totalSlots = 20,
    this.columns = 5,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final spacing = 8.0;
    final gridPadding = 12.0;
    final panelWidth = size.width * 0.4;
    final gridWidth = panelWidth - gridPadding * 2;
    final cellSize = ((gridWidth - (columns - 1) * spacing) / columns)
        .floorToDouble();
    final rows = (totalSlots + columns - 1) ~/ columns; // expect 4
    final gridHeight = (rows * cellSize + (rows - 1) * spacing)
        .floorToDouble();
    final headerApprox = 48.0 + 12.0 + 1.0; 
    final panelHeight = (gridHeight + gridPadding * 2 + headerApprox)
        .floorToDouble()
        .clamp(0.0, (size.height * 0.9).floorToDouble());

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
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                height: gridHeight,
                child: AnimatedBuilder(
                  animation: Inventory.instance,
                  builder: (context, _) {
                    final items = Inventory.instance.items;
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
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
                                    Icon(item.icon, size: 22, color: Colors.black87),
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
