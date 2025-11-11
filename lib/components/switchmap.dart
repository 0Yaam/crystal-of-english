
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../main.dart';



class SwitchMap extends PositionComponent with HasGameRef<MyGame> {
  final String targetMap;
  final Vector2 spawn;
  final bool oneShot;
  final bool debug;

  SwitchMap({
    required Vector2 position,
    required Vector2 size,
    required this.targetMap,
    required this.spawn,
    this.oneShot = false,
    this.debug = false,
    int zPriority = 5,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: zPriority,
        );

  late final RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _hitbox = RectangleHitbox(size: size, position: Vector2.zero())
      ..collisionType = CollisionType.passive;
    add(_hitbox);
  }

  bool _triggered = false;

  @override
  void update(double dt) {
    super.update(dt);
    final p = gameRef.player;


    final r1 = ui.Rect.fromLTWH(position.x, position.y, size.x, size.y);
    final r2 = ui.Rect.fromLTWH(p.position.x - p.size.x / 2,
        p.position.y - p.size.y / 2, p.size.x, p.size.y);

    if (r1.overlaps(r2)) {
      if (!_triggered) {
        _triggered = true;
        gameRef.loadMap(targetMap, spawn: spawn);
        if (oneShot) {
          removeFromParent();
        }
      }
    } else {
      _triggered = false;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (!debug) return;

    final paint = ui.Paint()
      ..color = const ui.Color(0x8800FF00)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;


    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }
}
