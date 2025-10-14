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
        builder: (ctx) => const AlertDialog(
          content: Text('Hành trang đã đầy'),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mua ${item.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mua')),
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

  Widget _grid(List<dynamic> items, {bool clickable = false}) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        final GameItem? item = index < items.length ? items[index] as GameItem : null;
        final tile = Container(
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
                    Icon(item.icon, size: 24, color: Colors.black87),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        );
        if (clickable && item != null) {
          return InkWell(onTap: () => _buy(item), child: tile);
        }
        return tile;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const spacing = 12.0;
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width * 0.92),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gridSpacing = 8.0;
                const gridCols = 5;
                const gridRows = 4;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront, size: 18),
                          const SizedBox(width: 6),
                          const Text('Gian hàng'),
                          const Spacer(),
                          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0, bottom: 6),
                                    child: Text('Hàng của NPC'),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, c) {
                                      final gridWidth = c.maxWidth;
                                      final cellSize = ((gridWidth - (gridCols - 1) * gridSpacing) / gridCols)
                                          .floorToDouble();
                                      final gridHeight = (gridRows * cellSize + (gridRows - 1) * gridSpacing)
                                          .floorToDouble();
                                      return SizedBox(
                                        height: gridHeight,
                                        child: _grid(npcItems, clickable: true),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: spacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4.0, bottom: 6),
                                  child: Text('Hành trang của bạn'),
                                ),
                                AnimatedBuilder(
                                  animation: Inventory.instance,
                                  builder: (context, _) {
                                    return LayoutBuilder(
                                      builder: (context, c) {
                                        final gridWidth = c.maxWidth;
                                        final cellSize = ((gridWidth - (gridCols - 1) * gridSpacing) / gridCols)
                                            .floorToDouble();
                                        final gridHeight = (gridRows * cellSize + (gridRows - 1) * gridSpacing)
                                            .floorToDouble();
                                        return SizedBox(
                                          height: gridHeight,
                                          child: _grid(Inventory.instance.items),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
