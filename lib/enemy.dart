import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'components/enemy_wander.dart' show EnemyType;
import 'main.dart' show MyGame;

/// Enemy NPC that wanders randomly and triggers battle when player gets close.
/// Uses animation system similar to player.dart with sprite sheets.
///
/// ANIMATION SYSTEM:
/// - Uses two sprite sheets per enemy type: idle.png and walk_around.png
/// - Each sheet has frames arranged horizontally (single row)
/// - Cycles through frames every 0.12 seconds while moving
/// - Shows idle frame when stopped
///
/// MOVEMENT SYSTEM:
/// - Moves in 4 cardinal directions only (up, down, left, right)
/// - Changes direction randomly every few seconds
/// - Stops for 10 seconds every cycle to show idle animation
/// - Flips sprite horizontally for left/right movement
class Enemy extends PositionComponent with HasGameRef<MyGame> {
  final ui.Rect patrolRect;
  final double speed;
  final double triggerRadius;
  final EnemyType enemyType;

  Enemy({
    required this.patrolRect,
    this.speed = 40,
    this.triggerRadius = 48,
    required this.enemyType,
  }) : super(anchor: Anchor.center, priority: 15);

  // Enemy type determines which folder to load sprites from
  String get _basePath {
    switch (enemyType) {
      case EnemyType.normal:
        return 'characters/enemy/at_main/orc/';
      case EnemyType.strong:
        return 'characters/enemy/at_main/plant/';
      case EnemyType.miniboss:
        return 'characters/enemy/at_main/orc2/';
      case EnemyType.boss:
        return 'characters/enemy/at_main/vampire/';
    }
  }



  final Random _rng = Random();
  bool _triggered = false;

  // Animation system (like player.dart)
  late final SpriteComponent _spriteComp;
  ui.Image? _idleSheet;
  ui.Image? _walkSheet;
  double _tileSize = 32;
  late final List<Sprite> _idleFrames;
  late final List<Sprite> _walkFrames;

  // Animation state
  bool _isMoving = false;
  int _currentFrame = 0;
  int _currentRow = 1; // Start with row 1 (down)
  int _lastFrame = -1;
  int _lastRow = -1;
  double _frameTime = 0;
  static const double _stepTime = 0.12; // same as player

  // Movement and idle timing
  // Single state counter: counts seconds in current state
  double _stateCount = 0.0;
  static const double _moveSeconds = 10.0; // stay moving for 10s then switch to idle
  static const double _idleSeconds = 5.0; // stay idle for 5s then switch to moving
  Vector2 _currentDirection = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load sprite sheets for this enemy type
    _walkSheet = await gameRef.images.load('${_basePath}walk_around.png');
    _idleSheet = await gameRef.images.load('${_basePath}idle.png');

    _tileSize = _inferSquareTileSize(_walkSheet!);

    // Build frame arrays (single row each)
    // Note: _buildRowFrames expects the sheet image; the walk sheet builds walk frames, idle builds idle frames
    _walkFrames = _buildRowFrames(_walkSheet!);
    _idleFrames = _buildRowFrames(_idleSheet!);

    // Build a SpriteAnimation for idle so we can advance idle frames easily
    // We'll use _idleFrames list and advance _currentFrame while idle.

    // Visual size matches player
    size = Vector2.all(40);
    _spriteComp = SpriteComponent(
      sprite: _idleFrames.first,
      size: size,
      anchor: Anchor.center,
      priority: 15,
    );
    await add(_spriteComp);

    // Spawn at random point within patrol area
    final x = patrolRect.left + _rng.nextDouble() * patrolRect.width;
    final y = patrolRect.top + _rng.nextDouble() * patrolRect.height;
    position = Vector2(x, y);

  // Start with moving state so the NPC immediately begins the move->idle loop
  _isMoving = true;
  _stateCount = 0.0; // start counting seconds in current state
    _pickRandomDirection();
    // Set an initial row based on direction
    if (_currentDirection.y > 0) {
      _currentRow = 1; // down
    } else if (_currentDirection.y < 0) {
      _currentRow = 2; // up
    } else if (_currentDirection.x < 0) {
      _currentRow = 3; // left
    } else if (_currentDirection.x > 0) {
      _currentRow = 4; // right
    } else {
      _currentRow = 1;
    }
    _currentFrame = 0;
    // Force initial sprite update
    _frameTime = 0;
    _lastFrame = -1;
    _lastRow = -1;
    _applyFrameIfChanged();
  }

  double _inferSquareTileSize(ui.Image image) {
    final w = image.width;
    final h = image.height;
    if (w % h == 0) return h.toDouble();
    if (h % w == 0) return w.toDouble();
    int a = w, b = h;
    while (b != 0) {
      final t = a % b / 2;
      a = b;
      b = t.toInt();
    }
    return a > 0 ? a.toDouble() : 16.0;
  }

  List<Sprite> _buildRowFrames(ui.Image image) {
    final cols = (image.width / _tileSize).floor().clamp(1, 9999);
    final rows = (image.height / _tileSize).floor().clamp(1, 9999);
    final List<Sprite> frames = <Sprite>[];

    // Build frames for all rows and columns
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        frames.add(
          Sprite(
            image,
            srcPosition: Vector2(c * _tileSize, r * _tileSize),
            srcSize: Vector2(_tileSize, _tileSize),
          ),
        );
      }
    }
    return frames;
  }

  /// Get frame index for walk animation based on row and column
  int _getWalkFrameIndex(int row, int col) {
    final cols = (_walkSheet!.width / _tileSize).floor();
    return row * cols + col;
  }

  /// Get frame index for idle animation based on row and column
  int _getIdleFrameIndex(int row, int col) {
    final cols = (_idleSheet!.width / _tileSize).floor();
    return row * cols + col;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isMounted) return;
    if (_triggered) return;

    // State counting: increment seconds spent in the current state and switch when thresholds are reached
    if (_isMoving) {
      _stateCount += dt;
      if (_stateCount >= _moveSeconds) {
        // Switch to idle
        _isMoving = false;
        _stateCount = 0.0;
        _currentDirection = Vector2.zero();
        _currentFrame = 0;
        // Reset animation timing/state so idle frame(s) show immediately
        _frameTime = 0;
        _lastFrame = -1;
        _lastRow = -1;
        _applyFrameIfChanged();
      }
    } else {
      _stateCount += dt;

      // Advance idle animation
      _frameTime += dt;
      if (_frameTime >= _stepTime) {
        _frameTime = 0;
        final cols = (_idleSheet!.width / _tileSize).floor();
        _currentFrame = (_currentFrame + 1) % cols;
        _applyFrameIfChanged();
      }

      if (_stateCount >= _idleSeconds) {
        // Switch to moving
        _isMoving = true;
        _stateCount = 0.0;
        _pickRandomDirection();
        _currentFrame = 0;
        // Reset animation timing/state so walk frame shows immediately
        _frameTime = 0;
        _lastFrame = -1;
        _lastRow = -1;
        _applyFrameIfChanged();
      }
    }

    // Handle movement
    if (_isMoving && !_currentDirection.isZero()) {
      // Move in current direction
      final step = _currentDirection * (speed * dt);
      final tentative = position + step;

      // Detect if the tentative move would go outside patrolRect
      bool hitEdge = false;
      // Check X
      if (tentative.x < patrolRect.left) {
        position.x = patrolRect.left;
        hitEdge = true;
      } else if (tentative.x > patrolRect.right) {
        position.x = patrolRect.right;
        hitEdge = true;
      } else {
        position.x = tentative.x;
      }
      // Check Y
      if (tentative.y < patrolRect.top) {
        position.y = patrolRect.top;
        hitEdge = true;
      } else if (tentative.y > patrolRect.bottom) {
        position.y = patrolRect.bottom;
        hitEdge = true;
      } else {
        position.y = tentative.y;
      }

      if (hitEdge) {
        // Stop movement at edge and enter idle state
        _isMoving = false;
        _currentDirection = Vector2.zero();
        // reset state counter so idleSeconds countdown begins
        _stateCount = 0.0;
        _currentFrame = 0;
        _frameTime = 0;
        _lastFrame = -1;
        _lastRow = -1;
        _applyFrameIfChanged();
        // return early to let idle animation take effect this frame
        return;
      }

      // Set row based on movement direction
      if (_currentDirection.y > 0) {
        _currentRow = 1; // down
      } else if (_currentDirection.y < 0) {
        _currentRow = 2; // up
      } else if (_currentDirection.x < 0) {
        _currentRow = 3; // left
      } else if (_currentDirection.x > 0) {
        _currentRow = 4; // right
      }

      // Advance walk animation
      _frameTime += dt;
      if (_frameTime > _stepTime) {
        _frameTime = 0;
        final cols = (_walkSheet!.width / _tileSize).floor();
        _currentFrame = (_currentFrame + 1) % cols;
      }
      _applyFrameIfChanged();

      // Keep within patrol bounds just in case
      position.x = position.x.clamp(patrolRect.left, patrolRect.right);
      position.y = position.y.clamp(patrolRect.top, patrolRect.bottom);
    }

    // Check battle trigger
    final p = gameRef.player;
    final d = p.position.distanceTo(position);
    if (d <= triggerRadius) {
      _triggered = true;
      gameRef.enterBattle(enemyType: enemyType);
      removeFromParent();
    }
  }

  void _pickRandomDirection() {
    // Pick one of 4 cardinal directions
    final directions = [
      Vector2(0, -1), // up
      Vector2(0, 1), // down
      Vector2(-1, 0), // left
      Vector2(1, 0), // right
    ];
    _currentDirection = directions[_rng.nextInt(4)];
  }

  void _applyFrameIfChanged() {
    if (_currentFrame != _lastFrame || _currentRow != _lastRow) {
      final frames = _isMoving ? _walkFrames : _idleFrames;
      final frameIndex = _isMoving
          ? _getWalkFrameIndex(
              _currentRow - 1,
              _currentFrame,
            ) // Convert to 0-based row
          : _getIdleFrameIndex(
              _currentRow - 1,
              _currentFrame,
            ); // Convert to 0-based row

      if (frameIndex < frames.length) {
        _spriteComp.sprite = frames[frameIndex];
        _lastFrame = _currentFrame;
        _lastRow = _currentRow;
      }
    }
  }
}
