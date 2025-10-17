import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import '../main.dart' show MyGame;

enum EnemyType { normal, strong, miniboss, boss }

class EnemyWander extends SpriteComponent with HasGameRef<MyGame> {
  final ui.Rect patrolRect;
  final String spritePath;
  final double speed;
  final double triggerRadius;
  final EnemyType enemyType;

  EnemyWander({
    required this.patrolRect,
    required this.spritePath,
    this.speed = 40,
    this.triggerRadius = 48,
    this.enemyType = EnemyType.normal,
  }) : super(size: Vector2(32, 32), anchor: Anchor.center, priority: 15);

  final _rng = Random();
  Vector2? _target;
  bool _triggered = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load(spritePath);

    final x = patrolRect.left + _rng.nextDouble() * patrolRect.width;
    final y = patrolRect.top + _rng.nextDouble() * patrolRect.height;
    position = Vector2(x, y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isMounted) return;

    if (_triggered) return;

    if (_target == null) {
      _pickNewTarget();
    } else {
      final dir = (_target! - position);
      final dist = dir.length;
      if (dist < 2) {
        _target = null;
      } else {
        final step = (dir / dist) * (speed * dt);
        position += step;
      }
    }

    final p = gameRef.player;
    final d = p.position.distanceTo(position);
    if (d <= triggerRadius) {
      _triggered = true;
      gameRef.enterBattle(enemyType: enemyType);
      removeFromParent();
    }
  }

  void _pickNewTarget() {
    final tx = patrolRect.left + _rng.nextDouble() * patrolRect.width;
    final ty = patrolRect.top + _rng.nextDouble() * patrolRect.height;
    _target = Vector2(tx, ty);
  }
}
