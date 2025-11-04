import 'package:flutter/material.dart';
import '../state/inventory.dart';

class InventoryPanel extends StatelessWidget {
  final VoidCallback onClose;
  final int totalSlots;
  final int columns;

  const InventoryPanel({
    super.key,
    required this.onClose,
    this.totalSlots = 24,
    this.columns = 6,
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
    final gridHeight = (rows * cellSize + (rows - 1) * spacing).floorToDouble();
    final headerApprox = 48.0 + 12.0 + 1.0;
    final panelHeight = (gridHeight + gridPadding * 2 + headerApprox)
        .floorToDouble()
        .clamp(0.0, (size.height * 0.9).floorToDouble());

    // Use Stack to layer slots over the backpack image
    // Use Stack to layer slots over the new backpack image (backPack.png)
    // 6x4 grid, 24 slots, matching the new image
    // Make slot boxes smaller and keep them aligned with the image grid
    // Render inside an aspect-ratio box matching the backpack art so
    // the grid can be positioned by percentages and scale together.
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 700, // base art width
          height: 560, // base art height (aspect ~1.25)
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'images/Back_Pack_Nogrid.png',
                  fit: BoxFit.fill,
                ),
              ),
              // Title + close (anchored to the art coordinates)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 18,
                      color: Colors.brown,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Hành trang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClose,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Image.asset(
                          'images/X_Button.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Grid overlay computed from a percentage rect so it stays aligned
              // if the art scales.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Inventory.instance,
                  builder: (context, _) {
                    final items = Inventory.instance.items;
                    const int rows = 4;
                    final int cols = columns;
                    // Define the grid rectangle as percentages of the art box.
                    // Tweak these if the art grid area changes.
                    const double gridLeftPct = 0.10; // move grid a bit lefter
                    const double gridTopPct = 0.20;
                    const double gridRightPct = 0.10; // balance right margin
                    const double gridBottomPct = 0.22; // bottom margin
                    const double spacingPx = 9.0; // 2px gap between slots

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        final double h = constraints.maxHeight;
                        final double left = w * gridLeftPct;
                        final double top = h * gridTopPct;
                        final double right = w * gridRightPct;
                        final double bottom = h * gridBottomPct;
                        final double gridW = w - left - right;
                        final double gridH = h - top - bottom;
                        // account for spacing between cells
                        final double cellWidth =
                            (gridW - spacingPx * (cols - 1)) / cols;
                        final double cellHeight =
                            (gridH - spacingPx * (rows - 1)) / rows;
                        final double cell = cellWidth < cellHeight
                            ? cellWidth
                            : cellHeight;
                        final double totalW =
                            cell * cols + spacingPx * (cols - 1);
                        final double totalH =
                            cell * rows + spacingPx * (rows - 1);
                        final double startX = left + (gridW - totalW) / 2;
                        final double startY = top + (gridH - totalH) / 2;

                        final List<Widget> slotWidgets = [];
                        const double inset =
                            2.0; // shrink each slot by 2px total
                        for (int r = 0; r < rows; r++) {
                          for (int c = 0; c < cols; c++) {
                            final int index = r * cols + c;
                            final item = index < items.length
                                ? items[index]
                                : null;
                            final double x =
                                startX + c * (cell + spacingPx) + inset;
                            final double y =
                                startY + r * (cell + spacingPx) + inset;
                            final double renderSize = (cell - 2.0).clamp(
                              0,
                              cell,
                            );
                            slotWidgets.add(
                              Positioned(
                                left: x,
                                top: y + 10,
                                child: Container(
                                  width: renderSize - 2,
                                  height: renderSize - 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1a1a2e),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.brown.shade300,
                                        offset: const Offset(-1, -1),
                                        blurRadius: 0,
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: Colors.brown.shade300,
                                        offset: const Offset(-2, -2),
                                        blurRadius: 0,
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: Colors.brown.shade900
                                            .withOpacity(0.6),
                                        offset: const Offset(1, 1),
                                        blurRadius: 0,
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: Colors.brown.shade900
                                            .withOpacity(0.6),
                                        offset: const Offset(2, 2),
                                        blurRadius: 0,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.brown.shade800,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  // Gold-like stroke similar to the art frame
                                  foregroundDecoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFB88A54),
                                      width: 4,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: item == null
                                      ? const SizedBox.shrink()
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              item.icon,
                                              size: renderSize * 0.5,
                                              color: const Color.fromARGB(
                                                255,
                                                255,
                                                255,
                                                255,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: renderSize * 0.22,
                                                color: const Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          }
                        }
                        return Stack(children: slotWidgets);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
