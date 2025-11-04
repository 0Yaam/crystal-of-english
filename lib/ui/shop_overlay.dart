import 'package:flutter/material.dart';
import '../state/inventory.dart';

class ShopOverlay extends StatefulWidget {
  static const id = 'ShopOverlay';

  final VoidCallback onClose;
  final int capacity;
  const ShopOverlay({super.key, required this.onClose, this.capacity = 20});

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay> {
  late List<GameItem> npcItems;

  // Adjustable positions for the foreground images
  static const Offset kEleonoreOffset = Offset(80, 0);
  static const Offset kBookOffset = Offset(-100, 0);

  @override
  void initState() {
    super.initState();
    npcItems = <GameItem>[
      const GameItem('Potion', Icons.local_drink),
      const GameItem('Elixir', Icons.science),
      const GameItem('Sword', Icons.gavel),
      const GameItem('Shield', Icons.shield),
      const GameItem('Scroll', Icons.menu_book),
      const GameItem('Boots', Icons.directions_walk),
    ];
  }

  Future<void> _buy(GameItem item) async {
    if (Inventory.instance.items.length >= widget.capacity) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => const AlertDialog(content: Text('Hành trang đã đầy')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mua ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mua'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final added = Inventory.instance.add(item);
      if (added) {
        setState(() {
          npcItems.remove(item);
        });
      }
    }
  }

  // Build Eleonore character image (left side)
  Widget _buildEleonoreImage(double height) {
    return SizedBox(
      width: 350,
      height: height,
      child: Image.asset('images/shop/Eleonore_Shop.png', fit: BoxFit.contain),
    );
  }

  // Build Book shop panel with slots (right side) using percent-based layout
  Widget _buildBookPanel(
    double baseWidth,
    double baseHeight,
    List<GameItem> items,
  ) {
    // The original art is 946x582; keep default size/aspect for Book_Shop_Nogrid.
    const double artW = 946;
    const double artH = 582;
    const int rowsPerPage = 5;
    const int colsPerPage = 4;

    // Page rectangles (fractions of the full art). Tune if the art changes.
    const Rect leftPage = Rect.fromLTWH(0.165, 0.155, 0.28, 0.68);
    const Rect rightPage = Rect.fromLTWH(0.535, 0.155, 0.28, 0.68);

    return SizedBox(
      width: baseWidth,
      height: baseHeight,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: artW,
          height: artH,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'images/shop/Book_Shop_Nogrid.png',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Image.asset(
                      'images/X_Button.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Build both pages' grids
              ..._buildPageGrid(leftPage, rowsPerPage, colsPerPage, items, 0),
              ..._buildPageGrid(
                rightPage,
                rowsPerPage,
                colsPerPage,
                items,
                rowsPerPage * colsPerPage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageGrid(
    Rect pageRectPct,
    int rows,
    int cols,
    List<GameItem> items,
    int startIndex,
  ) {
    return [
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final double x = pageRectPct.left * w;
            final double y = pageRectPct.top * h;
            final double pageW = pageRectPct.width * w;
            final double pageH = pageRectPct.height * h;
            const double spacingPx = 10.0; // 2px gap between slots
            final double cellWidth = (pageW - spacingPx * (cols - 1)) / cols;
            final double cellHeight = (pageH - spacingPx * (rows - 1)) / rows;
            final double cell = cellWidth < cellHeight ? cellWidth : cellHeight;
            final double totalW = cell * cols + spacingPx * (cols - 1);
            final double totalH = cell * rows + spacingPx * (rows - 1);
            final double startX = x + (pageW - totalW) / 2;
            final double startY = y + (pageH - totalH) / 2;

            final List<Widget> children = [];
            int idx = startIndex;
            for (int r = 0; r < rows; r++) {
              for (int c = 0; c < cols; c++) {
                final item = idx < items.length ? items[idx] : null;
                final double cx = startX + c * (cell + spacingPx) + 5;
                final double cy = startY + r * (cell + spacingPx) - 45;
                const double shrink = 1.0; // make slot smaller by 2px
                final double renderSize = (cell + 5) - shrink;
                children.add(
                  Positioned(
                    left: cx + shrink / 2,
                    top: cy + shrink / 2,
                    child: GestureDetector(
                      onTap: item != null ? () => _buy(item) : null,
                      child: SizedBox(
                        width: renderSize,
                        height: renderSize,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'images/Slot.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (item != null)
                              Positioned.fill(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: renderSize * 0.5,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: renderSize * 0.22,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                idx++;
              }
            }
            return Stack(children: children);
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Fix the panel to the art aspect; use default width for Book_Shop_Nogrid.
    const double bookArtW = 946;
    const double bookArtH = 582;
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: bookArtW + 600,
          height: bookArtH,
          child: Row(
            children: [
              Transform.translate(
                offset: kEleonoreOffset,
                child: _buildEleonoreImage(bookArtH),
              ),
              const Spacer(),
              Transform.translate(
                offset: kBookOffset,
                child: _buildBookPanel(bookArtW, bookArtH, npcItems),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
