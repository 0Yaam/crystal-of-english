import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    npcItems = const <GameItem>[];
    _loadItemsFromAssets();
  }

  Future<void> _loadItemsFromAssets() async {
    try {
      // Read the Flutter asset manifest to discover all assets under items folder
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestJson) as Map<String, dynamic>;
      const prefix = 'assets/images/items/';

      final List<String> assetPaths = manifest.keys
          .where((k) => k.startsWith(prefix) && (k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.jpeg') || k.endsWith('.webp')))
          .toList()
        ..sort();

      final items = assetPaths.map((path) {
        // Derive a simple name from filename without extension
        final filename = path.split('/').last;
        final dot = filename.lastIndexOf('.');
        final base = dot >= 0 ? filename.substring(0, dot) : filename;
        return GameItem(base, path);
      }).toList(growable: false);

      setState(() {
        npcItems = items;
        // Expand player inventory capacity to match number of items
        Inventory.instance.capacity = npcItems.length;
        _loading = false;
      });
    } catch (e) {
      // If something goes wrong, keep list empty but don't crash
      debugPrint('Failed to load item assets: $e');
      setState(() {
        _loading = false;
      });
    }
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

  Widget _grid(
    List<GameItem> items, {
    bool clickable = false,
    required int columns,
    int? totalSlotsOverride,
  }) {
    final totalSlots = totalSlotsOverride ?? items.length;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        final GameItem? item = index < items.length ? items[index] : null;
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
                                      final total = npcItems.length;
                                      final rows = total == 0 ? 1 : ((total + gridCols - 1) ~/ gridCols);
                                      final gridHeight = (rows * cellSize + (rows - 1) * gridSpacing)
                                          .floorToDouble();

                                      if (_loading) {
                                        return SizedBox(
                                          height: cellSize + gridSpacing,
                                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        );
                                      }

                                      if (npcItems.isEmpty) {
                                        return SizedBox(
                                          height: cellSize + gridSpacing,
                                          child: const Center(
                                            child: Text('Không tìm thấy item trong assets/images/items'),
                                          ),
                                        );
                                      }

                                      return SizedBox(
                                        height: gridHeight,
                                        child: _grid(npcItems, clickable: true, columns: gridCols),
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
                                        final total = Inventory.instance.capacity;
                                        final rows = total == 0 ? 1 : ((total + gridCols - 1) ~/ gridCols);
                                        final gridHeight = (rows * cellSize + (rows - 1) * gridSpacing)
                                            .floorToDouble();
                                        return SizedBox(
                                          height: gridHeight,
                                          child: _grid(
                                            Inventory.instance.items,
                                            columns: gridCols,
                                            totalSlotsOverride: Inventory.instance.capacity,
                                          ),
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
