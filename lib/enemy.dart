import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'components/enemy_wander.dart' show EnemyType;
import 'main.dart' show MyGame;















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


  late final SpriteComponent _spriteComp;
  ui.Image? _idleSheet;
  ui.Image? _walkSheet;
  double _tileSize = 32;
  late final List<Sprite> _idleFrames;
  late final List<Sprite> _walkFrames;


  bool _isMoving = false;
  int _currentFrame = 0;
  int _currentRow = 1;
  int _lastFrame = -1;
  int _lastRow = -1;
  double _frameTime = 0;
  static const double _stepTime = 0.12;



  double _stateCount = 0.0;
  static const double _moveSeconds = 10.0;
  static const double _idleSeconds = 5.0;
  Vector2 _currentDirection = Vector2.zero(); // Theo dõi hướng đang đi.

  @override
  Future<void> onLoad() async {
    await super.onLoad();


    _walkSheet = await gameRef.images.load('${_basePath}walk_around.png');
    _idleSheet = await gameRef.images.load('${_basePath}idle.png');

    _tileSize = _inferSquareTileSize(_walkSheet!);



    _walkFrames = _buildRowFrames(_walkSheet!);
    _idleFrames = _buildRowFrames(_idleSheet!);





    size = Vector2.all(40);
    _spriteComp = SpriteComponent(
      sprite: _idleFrames.first,
      size: size,
      anchor: Anchor.center,
      priority: 15,
    );
    await add(_spriteComp);


    // Spawn ngẫu nhiên trong vùng tuần tra cho đỡ máy móc.
    final x = patrolRect.left + _rng.nextDouble() * patrolRect.width;
    final y = patrolRect.top + _rng.nextDouble() * patrolRect.height + 12;
    position = Vector2(x, y);


  _isMoving = true;
  _stateCount = 0.0;
    _pickRandomDirection();

    if (_currentDirection.y > 0) {
      _currentRow = 1;
    } else if (_currentDirection.y < 0) {
      _currentRow = 2;
    } else if (_currentDirection.x < 0) {
      _currentRow = 3;
    } else if (_currentDirection.x > 0) {
      _currentRow = 4;
    } else {
      _currentRow = 1;
    }
    _currentFrame = 0;

    _frameTime = 0;
    _lastFrame = -1;
    _lastRow = -1;
    _applyFrameIfChanged();
  }

  // Tự đoán kích thước một tile vuông khi sheet không chuẩn chỉnh.
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


  int _getWalkFrameIndex(int row, int col) {
    final cols = (_walkSheet!.width / _tileSize).floor();
    return row * cols + col;
  }


  int _getIdleFrameIndex(int row, int col) {
    final cols = (_idleSheet!.width / _tileSize).floor();
    return row * cols + col;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isMounted) return;
    if (_triggered) return;


    if (_isMoving) {
      // Đang trong pha di chuyển ngẫu nhiên.
      _stateCount += dt;
      if (_stateCount >= _moveSeconds) {

        // Chạy đủ một pha thì nghỉ ngơi tí.
        _isMoving = false;
        _stateCount = 0.0;
        _currentDirection = Vector2.zero();
        _currentFrame = 0;

        _frameTime = 0;
        _lastFrame = -1;
        _lastRow = -1;
        _applyFrameIfChanged();
      }
    } else {
      _stateCount += dt;


      _frameTime += dt;
      if (_frameTime >= _stepTime) {
        _frameTime = 0;
        final cols = (_idleSheet!.width / _tileSize).floor();
        _currentFrame = (_currentFrame + 1) % cols;
        _applyFrameIfChanged();
      }

      if (_stateCount >= _idleSeconds) {

        // Đứng lâu quá thì random hướng đi tiếp.
        _isMoving = true;
        _stateCount = 0.0;
        _pickRandomDirection();
        _currentFrame = 0;

        _frameTime = 0;
        _lastFrame = -1;
        _lastRow = -1;
        _applyFrameIfChanged();
      }
    }


    if (_isMoving && !_currentDirection.isZero()) {

      final step = _currentDirection * (speed * dt);
      final tentative = position + step;


      bool hitEdge = false;

      if (tentative.x < patrolRect.left) {
        position.x = patrolRect.left;
        hitEdge = true;
      } else if (tentative.x > patrolRect.right) {
        position.x = patrolRect.right;
        hitEdge = true;
      } else {
        position.x = tentative.x;
      }

      if (tentative.y < patrolRect.top) {
        position.y = patrolRect.top;
        hitEdge = true;
      } else if (tentative.y > patrolRect.bottom) {
        position.y = patrolRect.bottom;
        hitEdge = true;
      } else {
    position.y = tentative.y + 0.0;
      }

      if (hitEdge) {

        // Vừa chạm biên thì đổi sang trạng thái đứng để khỏi vượt rào.
        _isMoving = false;
        _currentDirection = Vector2.zero();

        _stateCount = 0.0;
        _currentFrame = 0;
        _frameTime = 0;
        _lastFrame = -1;
        _lastRow = -1;
        _applyFrameIfChanged();

        return;
      }


      if (_currentDirection.y > 0) {
        _currentRow = 1;
      } else if (_currentDirection.y < 0) {
        _currentRow = 2;
      } else if (_currentDirection.x < 0) {
        _currentRow = 3;
      } else if (_currentDirection.x > 0) {
        _currentRow = 4;
      }


      _frameTime += dt;
      if (_frameTime > _stepTime) {
        _frameTime = 0;
        final cols = (_walkSheet!.width / _tileSize).floor();
        _currentFrame = (_currentFrame + 1) % cols;
      }
      _applyFrameIfChanged();


      // Không cho bước ra ngoài hình chữ nhật tuần tra.
      position.x = position.x.clamp(patrolRect.left, patrolRect.right);

  position.y = position.y.clamp(patrolRect.top + 8, patrolRect.bottom + 12);
    }


    final p = gameRef.player;
    final d = p.position.distanceTo(position);
    if (d <= triggerRadius) {
      // Người chơi tới gần là bật battle ngay.
      _triggered = true;
      gameRef.enterBattle(enemyType: enemyType);
      removeFromParent();
    }
  }

  void _pickRandomDirection() {

    final directions = [
      Vector2(0, -1),
      Vector2(0, 1),
      Vector2(-1, 0),
      Vector2(1, 0),
    ];
    // Đảo hướng đơn giản trong 4 hướng cơ bản.
    _currentDirection = directions[_rng.nextInt(4)];
  }

  void _applyFrameIfChanged() {
    if (_currentFrame != _lastFrame || _currentRow != _lastRow) {
      final frames = _isMoving ? _walkFrames : _idleFrames;
      final frameIndex = _isMoving
          ? _getWalkFrameIndex(
              _currentRow - 1,
              _currentFrame,
            )
          : _getIdleFrameIndex(
              _currentRow - 1,
              _currentFrame,
            );

      if (frameIndex < frames.length) {
        _spriteComp.sprite = frames[frameIndex];
        _lastFrame = _currentFrame;
        _lastRow = _currentRow;
      }
    }
  }
}
