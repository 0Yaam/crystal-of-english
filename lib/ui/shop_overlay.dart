import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/inventory.dart';

class ShopOverlay extends StatefulWidget {
  static const id = 'ShopOverlay';

  final VoidCallback onClose;
  final int capacity;
  final int Function()? getGold;
  final bool Function(int amount)? spendGold;
  const ShopOverlay({
    super.key,
    required this.onClose,
    this.capacity = 20,
    this.getGold,
    this.spendGold,
  });

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay> {
  late List<GameItem> npcItems;
  bool _loading = true;


  static const Offset kEleonoreOffset = Offset(80, 0);
  static const Offset kBookOffset = Offset(-100, 0);

  @override
  void initState() {
    super.initState();
    npcItems = const <GameItem>[];
    _loadItemsFromAssets();
  }

  Future<void> _loadItemsFromAssets() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest =
          json.decode(manifestJson) as Map<String, dynamic>;
      const prefix = 'assets/images/items/';

      final List<String> assetPaths = manifest.keys
          .where((k) => k.startsWith(prefix) &&
              (k.endsWith('.png') ||
                  k.endsWith('.jpg') ||
                  k.endsWith('.jpeg') ||
                  k.endsWith('.webp')))
          .toList()
        ..sort();

      final items = assetPaths.map((path) {
        final filename = path.split('/').last;
        final dot = filename.lastIndexOf('.');
        final base = dot >= 0 ? filename.substring(0, dot) : filename;
        final price = base.toLowerCase() == 'image1' ? 5 : 0;
        return GameItem(base, path, price: price);
      }).toList(growable: false);

      setState(() {
        npcItems = items;
        Inventory.instance.capacity = npcItems.length;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load item assets: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _buy(GameItem item) async {
    if (Inventory.instance.items.length >= Inventory.instance.capacity) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => const AlertDialog(
          content: Text('Hành trang đã đầy'),
        ),
      );
      return;
    }
    if (item.price > 0 && widget.getGold != null && widget.spendGold != null) {
      final have = widget.getGold!.call();
      if (have < item.price) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text('Không đủ vàng. Cần ${item.price}, đang có $have.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(item.price > 0 ? 'Mua ${item.name} với ${item.price} vàng?' : 'Mua ${item.name}?'),
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
      if (item.price > 0 && widget.spendGold != null) {
        final okSpend = widget.spendGold!.call(item.price);
        if (!okSpend) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              content: const Text('Không đủ vàng.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
      }
      final added = Inventory.instance.add(item);
      if (added) {
        setState(() {
          npcItems.remove(item);
        });
      }
    }
  }

  Widget _buildEleonoreImage(double height) {
    return SizedBox(
      width: 350,
      height: height,
      child: Image.asset(
        'assets/images/shop/Eleonore_Shop.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildBookPanel(
    double baseWidth,
    double baseHeight,
    List<GameItem> items,
  ) {
    const double artW = 946;
    const double artH = 582;
    const int rowsPerPage = 5;
    const int colsPerPage = 4;

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
                  'assets/images/shop/Book_shop_Nogrid.png',
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
                      'assets/images/X_Button.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              ..._buildPageGrid(
                leftPage,
                rowsPerPage,
                colsPerPage,
                items,
                0,
              ),
              ..._buildPageGrid(
                rightPage,
                rowsPerPage,
                colsPerPage,
                items,
                rowsPerPage * colsPerPage,
              ),
              if (_loading)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
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
            const double spacingPx = 10.0;
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
                final GameItem? item = idx < items.length ? items[idx] : null;
                final double cx = startX + c * (cell + spacingPx) + 5;
                final double cy = startY + r * (cell + spacingPx) - 45;
                const double shrink = 1.0;
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
                                'assets/images/Slot.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (item != null)
                              Positioned.fill(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: renderSize * 0.6,
                                      child: Image.asset(
                                        item.imageAssetPath,
                                        fit: BoxFit.contain,
                                      ),
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
