import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' as ft;
import 'package:flame/flame.dart';

class TiledObjectLoader {
  final ft.TiledComponent map;
  final World world;

  TiledObjectLoader(this.map, this.world);

  Future<void> loadLayer(String layerName) async {
    final objectGroup = map.tileMap.getLayer<ft.ObjectGroup>(layerName);
    if (objectGroup == null) {
      print("object layer '$layerName' does not exsist");
      return;
    }
    for (final obj in objectGroup.objects) {
      if (obj.gid != null) {
        final sprite = await _spriteFromGid(obj.gid!);
        if (sprite != null) {
          final spriteComp = SpriteComponent(
            sprite: sprite,
            position: Vector2(obj.x, obj.y - obj.height),
            size: Vector2(obj.width, obj.height),
          );

          await world.add(spriteComp);

          print("loaded object gid=${obj.gid}, layer=$layerName");
        } else {
          print("error gid=${obj.gid}");
        }
      }
    }
  }
  Future<Sprite?> _spriteFromGid(int gid) async {
    final tiledMap = map.tileMap.map;
    for (final tileset in tiledMap.tilesets) {
      final firstGid = tileset.firstGid ?? 0;
      final tileCount = tileset.tileCount ?? 0;
      final lastGid = firstGid + tileCount - 1;
      if (gid >= firstGid && gid <= lastGid) {
        final localId = gid - firstGid;
        if (localId < tileset.tiles.length) {
          final tile = tileset.tiles[localId];
          if (tile.image?.source != null) {
            final image = await Flame.images.load(tile.image!.source!);
            return Sprite(image);
          }
        }
        if (tileset.image?.source != null) {
          final image = await Flame.images.load(tileset.image!.source!);
          final columns = (tileset.image!.width! ~/ tileset.tileWidth!);
          final sx = (localId % columns) * tileset.tileWidth!;
          final sy = (localId ~/ columns) * tileset.tileHeight!;
          return Sprite(
            image,
            srcPosition: Vector2(sx.toDouble(), sy.toDouble()),
            srcSize: Vector2(
              tileset.tileWidth!.toDouble(),
              tileset.tileHeight!.toDouble(),
            ),
          );
        }
      }
    }
    return null;
  }
}
