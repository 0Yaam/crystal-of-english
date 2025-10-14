import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show EdgeInsets;
import 'package:flame/sprite.dart' show SpriteSheet;
import 'package:flame/effects.dart';

import '../components/quiz_panel.dart';
import '../quiz/quiz_models.dart';
import '../main.dart' show MyGame;
import '../ui/health.dart';
import 'enemy_wander.dart' show EnemyType;

const _kHeroIdlePng   = 'characters/maincharacter/Idle.png';
const _kHeroAttackPng = 'characters/maincharacter/Attack.png';
const _kHeroDeadPng   = 'characters/maincharacter/Dead.png';

// frame size
final Vector2 _kIdleFrameSize   = Vector2(64, 64);
final Vector2 _kAttackFrameSize = Vector2(96, 80);
final Vector2 _kDeadFrameSize   = Vector2(80, 64);

// số frame
const int _kIdleFrames   = 3;
const int _kAttackFrames = 8;
const int _kDeadFrames   = 8;

const double _kIdleStep   = 0.18;
const double _kAttackStep = 0.07;
const double _kDeadStep   = 0.08;

const int _kPostAnswerDelayMs = 800;

class BattleResult {
  final String outcome; 
  final int xpGained;

  BattleResult(this.outcome, {this.xpGained = 0});

  static BattleResult win({int xp = 0}) => BattleResult('win', xpGained: xp);
  static BattleResult lose() => BattleResult('lose', xpGained: 0);
  static BattleResult escape() => BattleResult('escape', xpGained: 0);
}

typedef BattleEndCallback = void Function(BattleResult result);

class HealthWithRightAlign extends Health {
  HealthWithRightAlign({
    required super.maxHearts,
    super.currentHearts,
    required super.fullHeartAsset,
    required super.emptyHeartAsset,
    super.heartSize = 32,
    super.spacing = 6,
    super.margin = const EdgeInsets.only(right: 16, top: 16),
    super.priority = 100001,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final w = maxHearts * heartSize + (maxHearts - 1) * spacing;
    size = Vector2(w, heartSize);
    for (var i = 0; i < maxHearts; i++) {
      final icon = children.elementAt(i) as SpriteComponent;
      icon.anchor = Anchor.topLeft;
      icon.position = Vector2((maxHearts - 1 - i) * (heartSize + spacing), 0);
    }
    setCurrent(currentHearts);
  }
}

class BossHealth extends Health {
  BossHealth({
    required super.maxHearts,
    super.currentHearts,
    required super.fullHeartAsset,
    required super.emptyHeartAsset,
    super.heartSize = 32,
    super.spacing = 6,
    super.margin = const EdgeInsets.only(right: 16, top: 16),
    super.priority = 100001,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final cols = 5;
    final rows = (maxHearts / cols).ceil();
    final w = cols * heartSize + (cols - 1) * spacing;
    final h = rows * heartSize + (rows - 1) * spacing;
    size = Vector2(w, h);
    for (var i = 0; i < maxHearts; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final icon = children.elementAt(i) as SpriteComponent;
      icon.anchor = Anchor.topLeft;
      icon.position = Vector2(
        (cols - 1 - col) * (heartSize + spacing),
        row * (heartSize + spacing),
      );
    }
    setCurrent(currentHearts);
  }
}

class BattleScene extends Component with HasGameReference<MyGame> {
  final BattleEndCallback onEnd;
  final EnemyType enemyType;

  BattleScene({required this.onEnd, required this.enemyType});

  // thưởng XP theo quai
  int _xpRewardFor(EnemyType t) {
    switch (t) {
      case EnemyType.normal:   return 8;
      case EnemyType.strong:   return 16;
      case EnemyType.miniboss: return 35;
      case EnemyType.boss:     return 80;
    }
  }

  // Hero animation
  late final PositionComponent heroRoot;
  late final SpriteAnimationComponent heroAnim;
  late SpriteAnimation _idleAnim;

  static const double battleScale = 1.8;
  static final Vector2 actorBaseSize = Vector2(48, 48);
  static const double baseGap = 70.0;

  late final World world;
  late final CameraComponent cam;
  late final PositionComponent hud;

  late Health heroHealth;
  late Health enemyHealth;

  late SpriteComponent enemy;
  late PositionComponent heroShadow;
  late PositionComponent enemyShadow;

  late final QuizRepository _quizRepo;
  late List<QuizQuestion> _pool;
  final String _topic = 'job';
  bool _takingTurn = false;
  bool _answering = false;
  QuizPanel? _panel;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    world = World();
    await add(world);

    cam = CameraComponent(world: world);
    cam.viewfinder.zoom = 2.0;
    await add(cam);

    final bgSprite = await Sprite.load('battlebackground/battle_background.png');
    final logicalBg = Vector2(320, 180);
    final screenSize = game.size;
    final scale = min(screenSize.x / logicalBg.x, screenSize.y / logicalBg.y);

    final bg = SpriteComponent(
      sprite: bgSprite,
      size: logicalBg * scale,
      anchor: Anchor.center,
      position: Vector2.zero(),
      priority: 0,
    );
    await world.add(bg);

    hud = PositionComponent(
      priority: 100000,
      size: screenSize,
      position: Vector2.zero(),
    );
    await cam.viewport.add(hud);

    heroHealth = Health(
      maxHearts: 5,
      currentHearts: 5,
      fullHeartAsset: 'hp/heart.png',
      emptyHeartAsset: 'hp/empty_heart.png',
      heartSize: 32,
      spacing: 6,
      margin: const EdgeInsets.only(left: 8, top: 4),
    )
      ..anchor = Anchor.topLeft
      ..position = Vector2(8, 4);
    await hud.add(heroHealth);

    // Enemy health
    final enemyMaxHearts = switch (enemyType) {
      EnemyType.normal => 2,
      EnemyType.strong => 3,
      EnemyType.miniboss => 5,
      EnemyType.boss => 10,
    };

    enemyHealth = (enemyType == EnemyType.boss)
        ? BossHealth(
            maxHearts: enemyMaxHearts,
            currentHearts: enemyMaxHearts,
            fullHeartAsset: 'hp/heart.png',
            emptyHeartAsset: 'hp/empty_heart.png',
            heartSize: 32,
            spacing: 6,
            margin: const EdgeInsets.only(right: 8, top: 4),
          )
        : HealthWithRightAlign(
            maxHearts: enemyMaxHearts,
            currentHearts: enemyMaxHearts,
            fullHeartAsset: 'hp/heart.png',
            emptyHeartAsset: 'hp/empty_heart.png',
            heartSize: 32,
            spacing: 6,
            margin: const EdgeInsets.only(right: 8, top: 4),
          );

    enemyHealth
      ..anchor = Anchor.topRight
      ..position = Vector2(screenSize.x - 8, 4);
    await hud.add(enemyHealth);

    final panelTop = screenSize.y * (1.0 - QuizPanel.panelHeightRatio);
    final centerX = screenSize.x / 2;
    final baselineY = panelTop - (8 * battleScale);
    final double halfGap = baseGap * battleScale;
    final Vector2 actorSize = actorBaseSize * battleScale;
    final heroDisplaySize = actorSize;

    final ui.Image idleImg   = await game.images.load(_kHeroIdlePng);
    final ui.Image attackImg = await game.images.load(_kHeroAttackPng);
    final ui.Image deadImg   = await game.images.load(_kHeroDeadPng);

    final idleSheet   = SpriteSheet(image: idleImg,   srcSize: _kIdleFrameSize);
    final attackSheet = SpriteSheet(image: attackImg, srcSize: _kAttackFrameSize);
    final deadSheet   = SpriteSheet(image: deadImg,   srcSize: _kDeadFrameSize);

    _idleAnim = idleSheet.createAnimation(
      row: 0,
      from: 0,
      to: _kIdleFrames - 1,
      stepTime: _kIdleStep,
      loop: true,
    );

    heroRoot = PositionComponent(
      size: heroDisplaySize,
      anchor: Anchor.bottomCenter,
      position: Vector2(centerX - 70 * battleScale, baselineY + 77),
      priority: 10,
    );

    heroAnim = SpriteAnimationComponent(
      animation: _idleAnim,
      size: heroDisplaySize,
      anchor: Anchor.bottomCenter,
      position: Vector2.zero(),
      priority: 10,
    );

    await heroRoot.add(heroAnim);
    await hud.add(heroRoot);

    heroShadow = _shadowAt(
      heroRoot.position,
      z: 9,
      width: 36 * battleScale,
      height: 10 * battleScale,
    );
    await hud.add(heroShadow);

    enemy = SpriteComponent(
      sprite: await Sprite.load('Joanna.png'),
      size: actorSize,
      anchor: Anchor.bottomCenter,
      position: Vector2(centerX + halfGap, baselineY),
      priority: 10,
    )..scale = Vector2(-1, 1);
    await hud.add(enemy);

    enemyShadow = _shadowAt(
      enemy.position,
      z: 9,
      width: 36 * battleScale,
      height: 10 * battleScale,
    );
    await hud.add(enemyShadow);

    // Load quiz & start turn
    _quizRepo = QuizRepository();
    _pool = await _quizRepo.loadTopic(_topic);
    await _nextTurn(attackSheet, deadSheet);
  }

 Future<void> _nextTurn(SpriteSheet attackSheet, SpriteSheet deadSheet) async {
  if (_takingTurn) return;
  _takingTurn = true;

  if (_pool.isEmpty) {
    onEnd(BattleResult.win());
    return;
  }

  final q = _pool.removeAt(0);

  _panel?.removeFromParent();
  _answering = false;

  _panel = QuizPanel(
    question: q,
    onAnswer: (isCorrect) async {
      if (_answering) return;
      _answering = true;

      if (isCorrect) {
        await _playHeroAttackOnce(attackSheet);
        enemyHealth.damage(1);
        await _hitFx(enemy.position);

        await Future.delayed(const Duration(milliseconds: _kPostAnswerDelayMs));

        _panel?.removeFromParent();
        _panel = null;

        if (enemyHealth.isDead) {
          final xp = _xpRewardFor(enemyType);
          onEnd(BattleResult.win(xp: xp));
          return;
        }

        _takingTurn = false;
        await _nextTurn(attackSheet, deadSheet);
      } else {
        heroHealth.damage(1);
        await _hitFx(heroRoot.position);

        if (heroHealth.isDead) {
          await _playHeroDeadOnce(deadSheet);
          await Future.delayed(const Duration(milliseconds: _kPostAnswerDelayMs));
          _panel?.removeFromParent();
          _panel = null;
          onEnd(BattleResult.lose());
          return;
        }

        await Future.delayed(const Duration(milliseconds: _kPostAnswerDelayMs));

        _panel?.removeFromParent();
        _panel = null;

        _takingTurn = false;
        await _nextTurn(attackSheet, deadSheet);
      }
    },
  );

  await hud.add(_panel!);
}


  // animation helper
  Future<void> _playHeroAttackOnce(SpriteSheet sheet) async {
    final anim = sheet.createAnimation(
      row: 0,
      from: 0,
      to: _kAttackFrames - 1,
      stepTime: _kAttackStep,
      loop: false,
    );
    heroAnim.animation = anim;
    final durMs = (_kAttackFrames * _kAttackStep * 1000).round();
    await Future.delayed(Duration(milliseconds: durMs));
    if (heroAnim.isMounted) {
      heroAnim.animation = _idleAnim;
    }
  }

  Future<void> _playHeroDeadOnce(SpriteSheet sheet) async {
    final anim = sheet.createAnimation(
      row: 0,
      from: 0,
      to: _kDeadFrames - 1,
      stepTime: _kDeadStep,
      loop: false,
    );
    heroAnim.animation = anim;
    final durMs = (_kDeadFrames * _kDeadStep * 1000).round();
    await Future.delayed(Duration(milliseconds: durMs));
  }

  // combat fx
  Future<void> _hitFx(Vector2 at) async {
    final fx = CircleComponent(
      radius: 8 * battleScale,
      anchor: Anchor.center,
      position: at + Vector2(0, -28 * battleScale),
      paint: ui.Paint()..color = const ui.Color(0x88FFFFFF),
      priority: 20,
    );
    await hud.add(fx);
    await fx.add(OpacityEffect.fadeOut(EffectController(duration: 0.15)));
    await Future.delayed(const Duration(milliseconds: 160));
    fx.removeFromParent();
  }

  PositionComponent _shadowAt(
    Vector2 pos, {
    int z = 0,
    double width = 36,
    double height = 10,
  }) {
    return _ShadowOval(
      width: width,
      height: height,
      position: pos + Vector2(0, 2 * (width / 36)),
      z: z,
    );
  }
}

class TextButtonHud extends PositionComponent with TapCallbacks {
  final String label;
  final void Function() onPressed;

  TextButtonHud({
    required this.label,
    required Vector2 position,
    required this.onPressed,
  }) : super(position: position, size: Vector2(80, 24), priority: 100002);

  bool _down = false;

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final bg = ui.Paint()
      ..color = _down ? const ui.Color(0xFF1B4F72) : const ui.Color(0xFF2E86DE);
    canvas.drawRect(size.toRect(), bg);

    final tp = TextPaint();
    tp.render(canvas, label, size / 2, anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent event) => _down = true;

  @override
  void onTapUp(TapUpEvent event) {
    _down = false;
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) => _down = false;
}

class _ShadowOval extends PositionComponent {
  final int z;

  _ShadowOval({
    required double width,
    required double height,
    required Vector2 position,
    this.z = 0,
  }) : super(
          position: position,
          size: Vector2(width, height),
          anchor: Anchor.center,
          priority: z,
        );

  @override
  void render(ui.Canvas canvas) {
    final paint = ui.Paint()..color = const ui.Color.fromARGB(33, 0, 0, 0);
    final rect = size.toRect().shift(ui.Offset(-size.x / 2, -size.y / 2));
    canvas.drawOval(rect, paint);
  }
}
