import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';

import '../main.dart';

class Coin extends SpriteAnimationComponent with TapCallbacks {
  final VoidCallback onCollected;
  final double interactRadius;
  final bool persistent;
  Coin({
    required Vector2 position,
    required this.onCollected,
    this.interactRadius = 50.0,
    this.persistent = false,
  }) : super(
         position: position,
         size: Vector2(16, 16),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final List<Sprite> sprites = [];
    for (int i = 1; i <= 4; i++) {
      sprites.add(await Sprite.load('coins/coin$i.png'));
    }
    animation = SpriteAnimation.spriteList(
      sprites,
      stepTime: 0.15,
      loop: true,
    );
    priority = 10;
  }

  @override
  bool onTapUp(TapUpEvent event) {
    final game = findGame() as MyGame?;
    if (game == null) return false;
    final distance = position.distanceTo(game.player.center);

    if (distance <= interactRadius) {
      onCollected();
      if (!persistent) {
        removeFromParent();
      }
      return true;
    }

    return false;
  }
}
