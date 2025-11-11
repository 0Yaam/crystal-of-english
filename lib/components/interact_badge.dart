import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../main.dart';

class InteractBadge extends PositionComponent
    with TapCallbacks, HasGameRef<MyGame> {
  final PositionComponent target;
  final VoidCallback onPressed;
  final double radius;
  final double gapToCenter;

  bool _enabled = false;

  InteractBadge({
    required this.target,
    required this.onPressed,
    this.radius = 56,
    this.gapToCenter = 0,
  }) : super(anchor: Anchor.center, priority: 200);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(radius * 2);
    _follow();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _follow();


    final p = gameRef.player;
    final dist = p.position.distanceTo(target.position);
    _enabled = dist <= radius;
  }

  void _follow() {
    if (!target.isMounted) return;
    position = target.position + Vector2(0, gapToCenter);
  }


  @override
  void onTapDown(TapDownEvent event) {
    if (_enabled) onPressed();
  }


  @override
  void render(Canvas canvas) {





  }
}
