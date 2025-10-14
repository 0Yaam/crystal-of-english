import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/input.dart';
import 'main.dart';
import 'components/collisionmap.dart';

class Player extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  JoystickComponent? joystick;

  static const double speed = 150;
  static const double stepTime = 0.12;
  static const double dtCap = 1 / 60;          
  static const double collisionCooldownMs = .15; 

  final Vector2 frameSize = Vector2(80, 80);
  static const int framesPerRow = 8;

  late Image spriteSheet;
  double frameTime = 0;
  int currentFrame = 0;
  int currentRow = 1; 
  int _lastFrame = -1;
  int _lastRow = -1;
  bool facingLeft = false;
  bool _lastFacingLeft = false;

  bool collided = false;
  JoystickDirection collisionDirection = JoystickDirection.idle;
  double _collisionCooldown = 0; 

  late final List<List<Sprite>> _frames; // [row][col]

  Player({required Vector2 position})
      : super(position: position, size: Vector2.all(80), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    spriteSheet = await gameRef.images.load('player.png');

    Sprite buildSprite(int row, int col) => Sprite(
          spriteSheet,
          srcPosition: Vector2(col * frameSize.x, row * frameSize.y),
          srcSize: frameSize,
        );

    _frames = List.generate(
      3, // rows: 0,1,2
      (r) => List.generate(framesPerRow, (c) => buildSprite(r, c)),
    );

    // start sprite
    currentRow = 1;
    currentFrame = 0;
    sprite = _frames[currentRow][currentFrame];
    _lastRow = currentRow;
    _lastFrame = currentFrame;

    final hb = RectangleHitbox(size: Vector2(6, 6), position: Vector2(37, 37))
      ..collisionType = CollisionType.active;
    if (kDebugMode) {
      hb.debugMode = true; 
    }
    add(hb);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (joystick == null) return;
    final d = dt > dtCap ? dtCap : dt;
    if (_collisionCooldown > 0) {
      _collisionCooldown -= d;
      if (_collisionCooldown < 0) _collisionCooldown = 0;
    }

    Vector2 velocity = Vector2.zero();
    final dir = joystick!.direction;

    final moveLeft  = dir == JoystickDirection.left;
    final moveRight = dir == JoystickDirection.right;
    final moveUp    = dir == JoystickDirection.up;
    final moveDown  = dir == JoystickDirection.down;

    bool lockLeft  = (collided && collisionDirection == JoystickDirection.left)  || (_collisionCooldown > 0 && collisionDirection == JoystickDirection.left);
    bool lockRight = (collided && collisionDirection == JoystickDirection.right) || (_collisionCooldown > 0 && collisionDirection == JoystickDirection.right);
    bool lockUp    = (collided && collisionDirection == JoystickDirection.up)    || (_collisionCooldown > 0 && collisionDirection == JoystickDirection.up);
    bool lockDown  = (collided && collisionDirection == JoystickDirection.down)  || (_collisionCooldown > 0 && collisionDirection == JoystickDirection.down);

    if (dir != JoystickDirection.idle) {
      if (moveLeft && !lockLeft) {
        velocity.x = -speed;
        currentRow = 0;
        facingLeft = true;
      } else if (moveRight && !lockRight) {
        velocity.x = speed;
        currentRow = 0;
        facingLeft = false;
      } else if (moveUp && !lockUp) {
        velocity.y = -speed;
        currentRow = 2;
      } else if (moveDown && !lockDown) {
        velocity.y = speed;
        currentRow = 1;
      }
    }

    if (!velocity.isZero()) {
      position += velocity * d;

      frameTime += d;
      if (frameTime > stepTime) {
        frameTime = 0;
        currentFrame = (currentFrame + 1) % framesPerRow;
      }
    }
    if (currentRow != _lastRow || currentFrame != _lastFrame) {
      sprite = _frames[currentRow][currentFrame];
      _lastRow = currentRow;
      _lastFrame = currentFrame;
    }
    if (facingLeft != _lastFacingLeft) {
      scale.x = facingLeft ? -1 : 1;
      _lastFacingLeft = facingLeft;
    }
    position.x = position.x.clamp(0, gameRef.mapBounds.width - size.x);
    position.y = position.y.clamp(0, gameRef.mapBounds.height - size.y);
  }
  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is HitboxComponent) {
      final dir = joystick?.direction ?? JoystickDirection.idle;
      if (dir != JoystickDirection.idle) {
        collisionDirection = dir;
        collided = true;
        _collisionCooldown = collisionCooldownMs; 
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is HitboxComponent) {
      collided = false;
      if (_collisionCooldown == 0) {
        collisionDirection = JoystickDirection.idle;
      }
    }
  }
}
