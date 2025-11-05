// Modular enemy animation map for alternative system
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show EdgeInsets;
import 'package:flame/sprite.dart' show SpriteSheet;

import '../components/quiz_panel.dart';
import '../quiz/quiz_models.dart';
import '../main.dart' show MyGame;
import '../ui/health.dart';
import 'enemy_wander.dart' show EnemyType;
import 'package:flame/effects.dart';

const _kHeroIdlePng = 'characters/maincharacter/Idle.png';
const _kHeroAttackPng = 'characters/maincharacter/Attack.png';
const _kHeroDeadPng = 'characters/maincharacter/Dead.png';
const _kHeroHurtPng = 'characters/maincharacter/Hurt.png';

// Hero frame sizes
final Vector2 _kHeroIdleFrameSize = Vector2(64, 64);
final Vector2 _kHeroAttackFrameSize = Vector2(96, 80);
final Vector2 _kHeroDeadFrameSize = Vector2(80, 64);
final Vector2 _kHeroHurtFrameSize = Vector2(64, 64);

// Hero animation frame counts (based on hero sprite sheets)
const int _kIdleFrames = 4;
const int _kAttackFrames = 8;
const int _kDeadFrames = 8;
const int _kHurtFrames = 4;

// Animation timing (seconds per frame)
const double _kIdleStep = 0.18;
const double _kAttackStep = 0.07;
const double _kDeadStep = 0.08;
const double _kHurtStep = 0.07;

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
      case EnemyType.normal:
        return 8;
      case EnemyType.strong:
        return 16;
      case EnemyType.miniboss:
        return 35;
      case EnemyType.boss:
        return 80;
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

  late Map<String, SpriteAnimation> _enemyAnims;

  late PositionComponent enemy;
  // Enemy animation sprites and helpers
  late SpriteAnimationComponent enemyAnim;
  late SpriteAnimation _enemyIdleAnim;

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

    final bgSprite = await Sprite.load(
      'battlebackground/battle_background.png',
    );
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

    heroHealth =
        Health(
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

    final ui.Image idleImg = await game.images.load(_kHeroIdlePng);
    final ui.Image attackImg = await game.images.load(_kHeroAttackPng);
    final ui.Image deadImg = await game.images.load(_kHeroDeadPng);
    final ui.Image hurtImg = await game.images.load(_kHeroHurtPng);

    final idleSheet = SpriteSheet(image: idleImg, srcSize: _kHeroIdleFrameSize);
    final attackSheet = SpriteSheet(
      image: attackImg,
      srcSize: _kHeroAttackFrameSize,
    );
    final deadSheet = SpriteSheet(image: deadImg, srcSize: _kHeroDeadFrameSize);

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
      position: Vector2(
        centerX - 70 * battleScale,
        baselineY + 50,
      ), // Move hero higher by 2px
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

    // Load enemy battle animations based on enemy type
    final String enemyFolder = switch (enemyType) {
      EnemyType.normal => 'characters/enemy/at_battle/orc/',
      EnemyType.strong => 'characters/enemy/at_battle/plant/',
      EnemyType.miniboss => 'characters/enemy/at_battle/orc2/',
      EnemyType.boss => 'characters/enemy/at_battle/vampire/',
    };

    // Modular enemy animation system with configurable frame sizes
    Map<String, SpriteAnimation> enemyAnimations = {};
    try {
      // Load sprite images (see attachments for actual images)
      final ui.Image eIdle = await game.images.load(
        '${enemyFolder}idle.png',
      ); // 4 frames, 64x64 each
      final ui.Image eAttack = await game.images.load(
        '${enemyFolder}attack.png',
      ); // 6 frames, 64x64 each
      final ui.Image eHurt = await game.images.load(
        '${enemyFolder}hurt.png',
      ); // 6 frames, 64x64 each
      final ui.Image eDeath = await game.images.load(
        '${enemyFolder}death.png',
      ); // 8 frames, 64x64 each

      // Frame sizes based on provided images
      const frameWidth = 64.0;
      const frameHeight = 64.0;

      // Frame counts based on image widths
      final idleFrameCount = (eIdle.width / frameWidth).floor(); // 4
      final attackFrameCount = (eAttack.width / frameWidth).floor(); // 6
      final hurtFrameCount = (eHurt.width / frameWidth).floor(); // 6
      final deathFrameCount = (eDeath.width / frameWidth).floor(); // 8

      // SpriteSheets
      final idleSheet = SpriteSheet(
        image: eIdle,
        srcSize: Vector2(frameWidth, frameHeight),
      );
      final attackSheet = SpriteSheet(
        image: eAttack,
        srcSize: Vector2(frameWidth, frameHeight),
      );
      final hurtSheet = SpriteSheet(
        image: eHurt,
        srcSize: Vector2(frameWidth, frameHeight),
      );
      final deathSheet = SpriteSheet(
        image: eDeath,
        srcSize: Vector2(frameWidth, frameHeight),
      );

      // Animations (all use row 0)
      enemyAnimations['idle'] = idleSheet.createAnimation(
        row: 0,
        from: 0,
        to: idleFrameCount - 1,
        stepTime: _kIdleStep,
        loop: true,
      );
      enemyAnimations['attack'] = attackSheet.createAnimation(
        row: 0,
        from: 0,
        to: attackFrameCount - 1,
        stepTime: _kAttackStep,
        loop: false,
      );
      enemyAnimations['hurt'] = hurtSheet.createAnimation(
        row: 0,
        from: 0,
        to: hurtFrameCount - 1,
        stepTime: _kHurtStep,
        loop: false,
      );
      enemyAnimations['death'] = deathSheet.createAnimation(
        row: 0,
        from: 0,
        to: deathFrameCount - 1,
        stepTime: _kDeadStep,
        loop: false,
      );

      // Store animation references for compatibility
      _enemyIdleAnim = enemyAnimations['idle']!;
      _enemyAnims = enemyAnimations;

      enemyAnim = SpriteAnimationComponent(
        animation: _enemyIdleAnim,
        size: actorSize,
        anchor: Anchor.bottomCenter,
        position: Vector2(centerX + halfGap, baselineY),
        priority: 10,
      )..scale = Vector2(1.4, 1.4);
      enemy = enemyAnim;

      await hud.add(enemyAnim);

      // Create sprite sheets with standard frame sizes
      // ...existing code for new animation logic...
    } catch (e) {
      // Fallback: keep the old Joanna static sprite so app doesn't crash if assets missing
      enemy = SpriteComponent(
        sprite: await Sprite.load('Joanna.png'),
        size: actorSize,
        anchor: Anchor.bottomCenter,
        position: Vector2(centerX + halfGap, baselineY),
        priority: 10,
      )..scale = Vector2(1, 1);
      await hud.add(enemy);
      // fallback: use hero idle anim for enemyAnim if needed
      _enemyIdleAnim = _idleAnim;
      _enemyAnims = {
        'idle': _idleAnim,
        'attack': _idleAnim,
        'hurt': _idleAnim,
        'death': _idleAnim,
      };
    }

    // Load quiz & start turn
    _quizRepo = QuizRepository();
    _pool = await _quizRepo.loadTopic(_topic);
    final hurtSheet = SpriteSheet(image: hurtImg, srcSize: _kHeroHurtFrameSize);
    await _nextTurn(attackSheet, deadSheet, hurtSheet);
  }

  Future<void> _nextTurn(
    SpriteSheet attackSheet,
    SpriteSheet deadSheet,
    SpriteSheet hurtSheet,
  ) async {
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

          // play enemy hurt animation if available
          await _playEnemyHurtOnce();

          await Future.delayed(
            const Duration(milliseconds: _kPostAnswerDelayMs),
          );

          _panel?.removeFromParent();
          _panel = null;

          if (enemyHealth.isDead) {
            // play death animation
            await _playEnemyDeathOnce();
            final xp = _xpRewardFor(enemyType);
            onEnd(BattleResult.win(xp: xp));
            return;
          }

          _takingTurn = false;
          await _nextTurn(attackSheet, deadSheet, hurtSheet);
        } else {
          heroHealth.damage(1);
          await _hitFx(heroRoot.position);
          // play hurt animation on hero
          await _playHeroHurtOnce(hurtSheet);

          // enemy attacks when player is incorrect
          await _playEnemyAttackOnce();

          if (heroHealth.isDead) {
            await _playHeroDeadOnce(deadSheet);
            await Future.delayed(
              const Duration(milliseconds: _kPostAnswerDelayMs),
            );
            _panel?.removeFromParent();
            _panel = null;
            onEnd(BattleResult.lose());
            return;
          }

          await Future.delayed(
            const Duration(milliseconds: _kPostAnswerDelayMs),
          );

          _panel?.removeFromParent();
          _panel = null;

          _takingTurn = false;
          await _nextTurn(attackSheet, deadSheet, hurtSheet);
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

  Future<void> _playHeroHurtOnce(SpriteSheet sheet) async {
    final anim = sheet.createAnimation(
      row: 0,
      from: 0,
      to: _kHurtFrames - 1,
      stepTime: _kHurtStep,
      loop: false,
    );
    heroAnim.animation = anim;
    final durMs = (_kHurtFrames * _kHurtStep * 1000).round();
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

  Future<void> _playEnemyAnim(String type) async {
    if (enemy is! SpriteAnimationComponent) return;
    final comp = enemy as SpriteAnimationComponent;
    final anim = _enemyAnims[type];
    if (anim == null) return;

    // Set the animation - this will automatically cycle through frames
    comp.animation = anim;

    // Calculate total duration from all frames
    double totalDuration = 0;
    for (final frame in anim.frames) {
      totalDuration += frame.stepTime;
    }

    // Wait for animation to complete
    final durMs = (totalDuration * 1000).round();
    await Future.delayed(Duration(milliseconds: durMs));

    // Return to idle animation (except for death)
    if (type != 'death' && comp.isMounted) {
      comp.animation = _enemyAnims['idle']!;
    }
  }

  // Enemy animation helpers
  // Removed unused _playEnemyAnimationOnce helper

  // Use the new modular animation helpers
  Future<void> _playEnemyAttackOnce() async => _playEnemyAnim('attack');
  Future<void> _playEnemyHurtOnce() async => _playEnemyAnim('hurt');
  Future<void> _playEnemyDeathOnce() async => _playEnemyAnim('death');

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
