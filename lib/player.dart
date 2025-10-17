import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'main.dart';
import 'components/collisionmap.dart';

/// Player character that responds to joystick input and animates using a sprite sheet.
///
/// ANIMATION SYSTEM:
/// - Uses a single sprite sheet (player.png) with a grid layout
/// - Sheet has 3 rows (0=left/right, 1=down, 2=up) and 8 columns per row
/// - Each frame is 80x80 pixels
/// - Animates by cycling through columns in the current row
/// - Frame timing controlled by stepTime (0.12 seconds per frame)
///
/// MOVEMENT SYSTEM:
/// - Responds to joystick input for 4-directional movement
/// - Speed is 150 pixels per second
/// - Changes animation row based on movement direction
/// - Flips sprite horizontally for left/right movement
///
/// COLLISION SYSTEM:
/// - Has a small collision hitbox (6x6 pixels) offset from center
/// - Prevents movement when colliding with obstacles
/// - Uses collision cooldown to prevent getting stuck
class Player extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  JoystickComponent? joystick;

  // Movement constants
  static const double speed = 150; // pixels per second
  static const double stepTime = 0.12; // seconds per animation frame
  static const double dtCap = 1 / 60; // cap delta time to prevent large jumps
  static const double collisionCooldownMs = .15; // prevent collision spam

  // Sprite sheet dimensions
  final Vector2 frameSize = Vector2(80, 80); // each frame is 80x80
  static const int framesPerRow = 8; // 8 frames per row in the sheet

  // Sprite sheet and animation state
  late Image spriteSheet; // loaded sprite sheet image
  double frameTime = 0; // accumulator for frame timing
  int currentFrame = 0; // current column (0-7)
  int currentRow = 1; // current row (0=side, 1=down, 2=up)
  int _lastFrame = -1; // previous frame for change detection
  int _lastRow = -1; // previous row for change detection
  bool facingLeft = false; // sprite flip state
  bool _lastFacingLeft = false; // previous flip state for change detection

  // Collision state
  bool collided = false; // currently colliding with something
  JoystickDirection collisionDirection =
      JoystickDirection.idle; // direction blocked by collision
  double _collisionCooldown = 0; // timer to prevent collision spam

  // 2D array of sprites: [row][column] for efficient frame lookup
  late final List<List<Sprite>> _frames;

  Player({required Vector2 position})
    : super(position: position, size: Vector2.all(80), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load the sprite sheet image
    spriteSheet = await gameRef.images.load('player.png');

    // Helper function to create a sprite from the sheet at given row/column
    Sprite buildSprite(int row, int col) => Sprite(
      spriteSheet,
      srcPosition: Vector2(
        col * frameSize.x,
        row * frameSize.y,
      ), // top-left corner of frame
      srcSize: frameSize, // size of the frame to extract
    );

    // Build 2D array of sprites: 3 rows × 8 columns
    _frames = List.generate(
      3, // rows: 0=side, 1=down, 2=up
      (r) => List.generate(framesPerRow, (c) => buildSprite(r, c)),
    );

    // Initialize starting state
    currentRow = 1; // start facing down
    currentFrame = 0; // first frame
    sprite = _frames[currentRow][currentFrame]; // set initial sprite
    _lastRow = currentRow; // track for change detection
    _lastFrame = currentFrame;

    // Add collision hitbox (smaller than visual sprite)
    final hb = RectangleHitbox(size: Vector2(6, 6), position: Vector2(37, 37))
      ..collisionType = CollisionType.active;
    if (kDebugMode) {
      hb.debugMode = true; // show hitbox in debug mode
    }
    add(hb);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (joystick == null) return; // no input, no movement

    // Cap delta time to prevent large jumps when game lags
    final d = dt > dtCap ? dtCap : dt;

    // Update collision cooldown timer
    if (_collisionCooldown > 0) {
      _collisionCooldown -= d;
      if (_collisionCooldown < 0) _collisionCooldown = 0;
    }

    Vector2 velocity = Vector2.zero(); // movement vector
    final dir = joystick!.direction; // get joystick input direction

    // Check which directions are being pressed
    final moveLeft = dir == JoystickDirection.left;
    final moveRight = dir == JoystickDirection.right;
    final moveUp = dir == JoystickDirection.up;
    final moveDown = dir == JoystickDirection.down;

    // Check if movement is blocked by collision in each direction
    bool lockLeft =
        (collided && collisionDirection == JoystickDirection.left) ||
        (_collisionCooldown > 0 &&
            collisionDirection == JoystickDirection.left);
    bool lockRight =
        (collided && collisionDirection == JoystickDirection.right) ||
        (_collisionCooldown > 0 &&
            collisionDirection == JoystickDirection.right);
    bool lockUp =
        (collided && collisionDirection == JoystickDirection.up) ||
        (_collisionCooldown > 0 && collisionDirection == JoystickDirection.up);
    bool lockDown =
        (collided && collisionDirection == JoystickDirection.down) ||
        (_collisionCooldown > 0 &&
            collisionDirection == JoystickDirection.down);

    // Process movement input and set animation row
    if (dir != JoystickDirection.idle) {
      if (moveLeft && !lockLeft) {
        velocity.x = -speed; // move left
        currentRow = 0; // use side animation row
        facingLeft = true; // flip sprite
      } else if (moveRight && !lockRight) {
        velocity.x = speed; // move right
        currentRow = 0; // use side animation row
        facingLeft = false; // don't flip sprite
      } else if (moveUp && !lockUp) {
        velocity.y = -speed; // move up
        currentRow = 2; // use up animation row
      } else if (moveDown && !lockDown) {
        velocity.y = speed; // move down
        currentRow = 1; // use down animation row
      }
    }

    // Apply movement and animate if moving
    if (!velocity.isZero()) {
      position += velocity * d; // update position

      // Advance animation frame timing
      frameTime += d;
      if (frameTime > stepTime) {
        frameTime = 0; // reset timer
        currentFrame =
            (currentFrame + 1) % framesPerRow; // cycle through frames
      }
    }

    // Update sprite if animation state changed
    if (currentRow != _lastRow || currentFrame != _lastFrame) {
      sprite = _frames[currentRow][currentFrame]; // set new sprite
      _lastRow = currentRow;
      _lastFrame = currentFrame;
    }

    // Flip sprite horizontally if facing direction changed
    if (facingLeft != _lastFacingLeft) {
      scale.x = facingLeft ? -1 : 1; // flip horizontally
      _lastFacingLeft = facingLeft;
    }

    // Keep player within map bounds
    position.x = position.x.clamp(0, gameRef.mapBounds.width - size.x);
    position.y = position.y.clamp(0, gameRef.mapBounds.height - size.y);
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is HitboxComponent) {
      // Get the current movement direction when collision occurs
      final dir = joystick?.direction ?? JoystickDirection.idle;
      if (dir != JoystickDirection.idle) {
        collisionDirection = dir; // remember which direction is blocked
        collided = true; // mark as colliding
        _collisionCooldown = collisionCooldownMs; // start cooldown timer
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is HitboxComponent) {
      collided = false; // no longer colliding
      if (_collisionCooldown == 0) {
        collisionDirection = JoystickDirection.idle; // clear blocked direction
      }
    }
  }
}
