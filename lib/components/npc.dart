
import 'dart:math';
import 'dart:ui' show Rect, Size;
import 'package:flame/components.dart';
import '../dialog/dialog_manager.dart';
import 'speechbubble.dart';
import 'interact_badge.dart';
import '../main.dart';

Vector2 tileCenter(int col, int row, {double tileSize = 16}) =>
    Vector2((col + 0.5) * tileSize, (row + 0.5) * tileSize);

class NpcAnimConfig {
  final Vector2 frameSize;
  final int amount;
  final double stepTime;
  final int amountPerRow;
  final Vector2 offset;
  NpcAnimConfig({
    required this.frameSize,
    required this.amount,
    this.stepTime = 0.12,
    this.amountPerRow = 0,
    Vector2? offset,
  }) : offset = offset ?? Vector2.zero();
}

enum InteractOrderMode {
  alwaysFromStart,
  rememberProgress,
  loop,
}

class Npc extends SpriteComponent with HasGameRef<MyGame> {
  final DialogManager manager;
  final String spriteAsset;
  final Vector2 srcPosition;
  final Vector2 srcSize;
  final NpcAnimConfig? anim;
  final int zPriority;
  final String? avatarAsset;
  final Vector2? avatarSrcPosition;
  final Vector2? avatarSrcSize;
  final Size avatarDisplaySize;
  final String? rightAvatarAsset;
  final Vector2? rightAvatarSrcPosition;
  final Vector2? rightAvatarSrcSize;
  final Size rightAvatarDisplaySize;
  final List<String> interactLines;
  int _interactIdx = 0;
  final InteractOrderMode interactOrderMode;
  final String? interactPrompt;
  final List<DialogueChoice> interactChoices;
  final Portrait? fixedRightPortrait;
  bool enableIdleChatter;
  final List<String> idleLines;
  int _idleIdx = 0;
  final double idleSpeakEvery;
  final double idleShowFor;
  final bool idleOnlyNearPlayer;
  final double idleTalkRadius;
  final double idleBubbleOffsetY;
  TimerComponent? _idleLoop;
  final _rnd = Random();
  final double interactRadius;
  final double interactGapToCenter;
  InteractBadge? _badge;
  SpeechBubble? _bubble;
  SpriteAnimationComponent? _animComp;

  Npc({
    required Vector2 position,
    required this.manager,


    this.spriteAsset = 'player.png',
    Vector2? srcPosition,
    Vector2? srcSize,
    this.anim,
    this.zPriority = 20,
    this.avatarAsset,
    this.avatarSrcPosition,
    this.avatarSrcSize,
    this.avatarDisplaySize = const Size(48, 48),
    this.rightAvatarAsset,
    this.rightAvatarSrcPosition,
    this.rightAvatarSrcSize,
    this.rightAvatarDisplaySize = const Size(48, 48),


    required this.interactLines,
    this.interactOrderMode = InteractOrderMode.alwaysFromStart,


    this.interactPrompt,
    this.interactChoices = const <DialogueChoice>[],
    this.fixedRightPortrait,


    this.enableIdleChatter = true,
    required this.idleLines,
    this.idleSpeakEvery = 4,
    this.idleShowFor = 2,
    this.idleOnlyNearPlayer = false,
    this.idleTalkRadius = 160,
    this.idleBubbleOffsetY = 0,


    this.interactRadius = 56,
    this.interactGapToCenter = 0,


    Vector2? size,
  })  : srcPosition = srcPosition ?? Vector2(0, 0),
        srcSize = srcSize ?? Vector2(80, 80),
        super(
          position: position,
          size: size ?? Vector2(80, 80),
          anchor: Anchor.center,
          priority: zPriority,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final img = await gameRef.images.load(spriteAsset);
    if (anim == null) {
      sprite = Sprite(img, srcPosition: srcPosition, srcSize: srcSize);
    } else {
      final cfg = anim!;
      final data = SpriteAnimationData.sequenced(
        amount: cfg.amount,
        stepTime: cfg.stepTime,
        textureSize: cfg.frameSize,
        amountPerRow: cfg.amountPerRow == 0 ? cfg.amount : cfg.amountPerRow,
        texturePosition: cfg.offset,
      );
      final animation = SpriteAnimation.fromFrameData(img, data);
      _animComp = SpriteAnimationComponent(
        animation: animation,
        size: size,
        anchor: Anchor.center,
        priority: zPriority,
      );
      await add(_animComp!);
      sprite = null;
    }
    _badge = InteractBadge(
      target: this,
      radius: interactRadius,
      gapToCenter: interactGapToCenter,
      onPressed: _handleInteractPressed,
    );
    parent?.add(_badge!);
    // Hiện vòng tròn gợi ý tương tác quanh NPC.
    if (enableIdleChatter && idleLines.isNotEmpty) {
      final jitter = _rnd.nextDouble() * 1.5;
      _idleLoop = TimerComponent(
        period: idleSpeakEvery,
        repeat: true,
        autoStart: false,
        onTick: _idleSpeakOnce,
      );
      add(_idleLoop!);
      add(TimerComponent(
        period: jitter,
        onTick: () {
          _idleSpeakOnce();
          _idleLoop?.timer.start();
        },
        removeOnFinish: true,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_badge != null && !_badge!.isMounted && parent != null) {
      parent!.add(_badge!);
      // Flame đôi khi remove component con, nên gắn lại khi cần.
    }


    try {
      final p = gameRef.player;
      final dist = p.position.distanceTo(position);
      final near = dist <= interactRadius;
      if (!manager.isOpen && near && (interactChoices.isNotEmpty || (interactPrompt != null && interactPrompt!.isNotEmpty))) {

        if (_bubble == null) {
          // Hiện bong bóng nho nhỏ để nhắc người chơi tương tác.
          final label = (interactPrompt != null && interactPrompt!.trim().length <= 28)
              ? interactPrompt!
              : 'Nói chuyện';
          final b = SpeechBubble(
            text: label,
            target: this,
            maxWidth: 160,
            padding: 8,
            gapToHead: 6,
          );
          if (parent != null) {
            parent!.add(b);
            _bubble = b;
          }
        }
      } else if (!near) {

        if (_bubble != null) {
          // Đi xa rồi thì tắt bong bóng cho đỡ rối màn hình.
          _bubble!.removeFromParent();
          _bubble = null;
        }
      }
    } catch (_) {}
  }
  void _handleInteractPressed() {
    if (manager.isOpen) return;
    if (interactChoices.isNotEmpty || (interactPrompt != null && interactPrompt!.isNotEmpty)) {
      _openInteractMenu();
      return;
    }
    _openInteractLinear();
  }
  void _openInteractMenu() {
    _removeBubble();
    final leftPortrait = Portrait(
      asset: avatarAsset ?? spriteAsset,
      src: _buildAvatarSrc(),
      size: avatarDisplaySize,
    );
    final Portrait? rightPortrait = fixedRightPortrait ??
        (rightAvatarAsset != null
            ? Portrait(
                asset: rightAvatarAsset!,
                src: _buildRightAvatarSrc(),
                size: rightAvatarDisplaySize,
              )
            : null);

    manager.show(
      text: interactPrompt ?? 'Bạn cần gì?',
      portrait: leftPortrait,
      rightPortrait: rightPortrait,
      choices: interactChoices,
    );
  }
  void _openInteractLinear() {
    if (interactLines.isEmpty) return;

    _removeBubble();

    final leftPortrait = Portrait(
      asset: avatarAsset ?? spriteAsset,
      src: _buildAvatarSrc(),
      size: avatarDisplaySize,
    );

    final script = <DialogueLine>[];
    switch (interactOrderMode) {
      case InteractOrderMode.alwaysFromStart:
        for (final t in interactLines) {
          script.add(DialogueLine(t, speaker: leftPortrait));
        }
        break;

      case InteractOrderMode.rememberProgress:
        final start = _interactIdx.clamp(0, interactLines.length);
        for (int i = start; i < interactLines.length; i++) {
          script.add(DialogueLine(interactLines[i], speaker: leftPortrait));
        }
        _interactIdx = interactLines.length;
        break;

      case InteractOrderMode.loop:
        if (_interactIdx >= interactLines.length) _interactIdx = 0;
        for (int i = 0; i < interactLines.length; i++) {
          final idx = (_interactIdx + i) % interactLines.length;
          script.add(DialogueLine(interactLines[idx], speaker: leftPortrait));
        }
        _interactIdx = (_interactIdx + 1) % interactLines.length;
        break;
    }

    if (script.isEmpty) return;
    manager.startLinear(script);
  }

  Rect _buildAvatarSrc() {
    if (avatarSrcPosition != null && avatarSrcSize != null) {
      return Rect.fromLTWH(
        avatarSrcPosition!.x, avatarSrcPosition!.y,
        avatarSrcSize!.x, avatarSrcSize!.y,
      );
    }
    if (anim != null) {
      final a = anim!;
      return Rect.fromLTWH(a.offset.x, a.offset.y, a.frameSize.x, a.frameSize.y);
    }
    return Rect.fromLTWH(srcPosition.x, srcPosition.y, srcSize.x, srcSize.y);
  }

  Rect? _buildRightAvatarSrc() {
    if (rightAvatarSrcPosition != null && rightAvatarSrcSize != null) {
      return Rect.fromLTWH(
        rightAvatarSrcPosition!.x, rightAvatarSrcPosition!.y,
        rightAvatarSrcSize!.x, rightAvatarSrcSize!.y,
      );
    }
    return null;
  }
  Future<void> _idleSpeakOnce() async {
    if (!enableIdleChatter) return;
    if (idleLines.isEmpty) return;
    if (manager.isOpen) return;

    if (idleOnlyNearPlayer) {
      // Nói chuyện phiếm chỉ khi người chơi đứng đủ gần.
      final p = gameRef.player;
      if (p.position.distanceTo(position) > idleTalkRadius) return;
    }

    final text = idleLines[_idleIdx % idleLines.length];
    _idleIdx++;
    _removeBubble();
    final b = SpeechBubble(
      text: text,
      target: this,
      maxWidth: 160,
      padding: 6,
      gapToHead: idleBubbleOffsetY,
    );
    if (parent != null) {
      await parent!.add(b);
      _bubble = b;
    }
    add(TimerComponent(
      period: idleShowFor,
      onTick: _removeBubble,
      removeOnFinish: true,
    ));
  }

  void startIdleChatter() {
    enableIdleChatter = true;
    _idleLoop?.timer.start();
  }

  void stopIdleChatter() {
    enableIdleChatter = false;
    _idleLoop?.timer.stop();
    _removeBubble();
  }

  void setIdleLines(List<String> lines, {bool resetIndex = true}) {
    idleLines
      ..clear()
      ..addAll(lines);
    if (resetIndex) _idleIdx = 0;
  }

  void setInteractLines(List<String> lines, {bool resetIndex = true}) {
    interactLines
      ..clear()
      ..addAll(lines);
    if (resetIndex) _interactIdx = 0;
  }

  void _removeBubble() {
    _bubble?.removeFromParent();
    _bubble = null;
  }

  void teleportTo(Vector2 p) => position = p;
  void teleportToTile(int col, int row, {double tileSize = 16}) =>
      position = tileCenter(col, row, tileSize: tileSize);

  @override
  void onRemove() {
    _removeBubble();
    _badge?.removeFromParent();
    _badge = null;
    super.onRemove();
  }
}
