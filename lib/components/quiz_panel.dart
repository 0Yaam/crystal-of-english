import 'dart:ui' as ui;
import 'dart:math'; // Added import for min function
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter/foundation.dart' show VoidCallback;

import '../quiz/quiz_models.dart';
import '../main.dart';

typedef OnAnswer = void Function(bool isCorrect);

class NineSliceSprite extends PositionComponent {
  final String assetPath;
  final double? sliceSize;

  NineSliceSprite({
    required this.assetPath,
    this.sliceSize,
    required super.size,
    required super.position,
    required super.priority,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load all 9 slice images
    final topLeft = await _loadImage('${assetPath}TopLeft.png');
    final top = await _loadImage('${assetPath}Top.png');
    final topRight = await _loadImage('${assetPath}TopRight.png');
    final left = await _loadImage('${assetPath}Left.png');
    final center = await _loadImage('${assetPath}Center.png');
    final right = await _loadImage('${assetPath}Right.png');
    final bottomLeft = await _loadImage('${assetPath}BottomLeft.png');
    final bottom = await _loadImage('${assetPath}Bottom.png');
    final bottomRight = await _loadImage('${assetPath}BottomRight.png');

    if (topLeft == null ||
        top == null ||
        topRight == null ||
        left == null ||
        center == null ||
        right == null ||
        bottomLeft == null ||
        bottom == null ||
        bottomRight == null) {
      print('[NineSliceSprite] Failed to load 9-slice images from $assetPath');
      return;
    }

    // Determine slice size automatically from corner if not provided
    final double s =
        sliceSize ?? min(topLeft.width.toDouble(), topLeft.height.toDouble());

    // Calculate dimensions
    final centerWidth = size.x - s * 2;
    final centerHeight = size.y - s * 2;

    // Add corner pieces
    await add(
      SpriteComponent(
        sprite: Sprite(topLeft),
        position: Vector2.zero(),
        size: Vector2.all(s),
        priority: priority,
      ),
    );

    await add(
      SpriteComponent(
        sprite: Sprite(topRight),
        position: Vector2(size.x - s, 0),
        size: Vector2.all(s),
        priority: priority,
      ),
    );

    await add(
      SpriteComponent(
        sprite: Sprite(bottomLeft),
        position: Vector2(0, size.y - s),
        size: Vector2.all(s),
        priority: priority,
      ),
    );

    await add(
      SpriteComponent(
        sprite: Sprite(bottomRight),
        position: Vector2(size.x - s, size.y - s),
        size: Vector2.all(s),
        priority: priority,
      ),
    );

    // Add edge pieces
    if (centerWidth > 0) {
      await _addTiledHorizontal(
        image: top,
        startX: s,
        y: 0,
        totalWidth: centerWidth,
        tileW: s,
        tileH: s,
      );

      await _addTiledHorizontal(
        image: bottom,
        startX: s,
        y: size.y - s,
        totalWidth: centerWidth,
        tileW: s,
        tileH: s,
      );
    }

    if (centerHeight > 0) {
      await _addTiledVertical(
        image: left,
        x: 0,
        startY: s,
        totalHeight: centerHeight,
        tileW: s,
        tileH: s,
      );

      await _addTiledVertical(
        image: right,
        x: size.x - s,
        startY: s,
        totalHeight: centerHeight,
        tileW: s,
        tileH: s,
      );
    }

    // Add center piece
    if (centerWidth > 0 && centerHeight > 0) {
      await add(
        SpriteComponent(
          sprite: Sprite(center),
          position: Vector2(s, s),
          size: Vector2(centerWidth, centerHeight),
          priority: priority,
        ),
      );
    }
  }

  Future<ui.Image?> _loadImage(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      print('[NineSliceSprite] Failed to load image: $path — $e');
      return null;
    }
  }

  // Tile an image horizontally across a span, cropping the last tile if needed.
  Future<void> _addTiledHorizontal({
    required ui.Image image,
    required double startX,
    required double y,
    required double totalWidth,
    required double tileW,
    required double tileH,
  }) async {
    double x = startX;
    double remaining = totalWidth;
    while (remaining > 0.0) {
      final drawW = remaining >= tileW ? tileW : remaining;
      // Crop source for partial tile to avoid stretching pattern
      final double cropRatio = drawW / tileW;
      final sprite = cropRatio >= 0.999
          ? Sprite(image)
          : Sprite(
              image,
              srcSize: Vector2(
                image.width.toDouble() * cropRatio,
                image.height.toDouble(),
              ),
            );
      await add(
        SpriteComponent(
          sprite: sprite,
          position: Vector2(x, y),
          size: Vector2(drawW, tileH),
          priority: priority,
        ),
      );
      x += drawW;
      remaining -= drawW;
    }
  }

  // Tile an image vertically across a span, cropping the last tile if needed.
  Future<void> _addTiledVertical({
    required ui.Image image,
    required double x,
    required double startY,
    required double totalHeight,
    required double tileW,
    required double tileH,
  }) async {
    double y = startY;
    double remaining = totalHeight;
    while (remaining > 0.0) {
      final drawH = remaining >= tileH ? tileH : remaining;
      final double cropRatio = drawH / tileH;
      final sprite = cropRatio >= 0.999
          ? Sprite(image)
          : Sprite(
              image,
              srcSize: Vector2(
                image.width.toDouble(),
                image.height.toDouble() * cropRatio,
              ),
            );
      await add(
        SpriteComponent(
          sprite: sprite,
          position: Vector2(x, y),
          size: Vector2(tileW, drawH),
          priority: priority,
        ),
      );
      y += drawH;
      remaining -= drawH;
    }
  }
}

class QuizPanel extends PositionComponent
    with TapCallbacks, HasGameReference<MyGame> {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  static const double panelHeightRatio = 0.68;
  bool _autoPlayed = false;
  bool _disabled = false;

  // layout
  late final double _leftW;
  late final double _panelY;
  late final double _panelH;
  // inner content area (between Top/Bottom borders with 15px padding)
  late final double _border;
  late final double _pad;
  late final double _innerTop;
  late final double _innerBottom;
  late final double _innerH;
  late final double _innerSidePad;

  QuizPanel({required this.question, required this.onAnswer})
    : super(priority: 100003);

  Future<ui.Image?> _loadUiImage(String raw) async {
    final candidates = <String>[
      raw,
      if (!raw.startsWith('assets/')) 'assets/$raw',
    ];
    for (final p in candidates) {
      try {
        final ByteData data = await rootBundle.load(p);
        final bytes = data.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (e) {
        print('[QuizPanel] Failed to load image: $p — $e');
      }
    }
    print('[QuizPanel] Image NOT FOUND: $raw (tried: $candidates)');
    return null;
  }

  Future<void> _playSoundRaw(String raw) async {
    final candidates = <String>[
      raw,
      if (!raw.startsWith('assets/')) 'assets/$raw',
    ];
    for (final p in candidates) {
      try {
        await FlameAudio.play(p);
        return;
      } catch (e) {
        print('[QuizPanel] Failed to play sound: $p — $e');
      }
    }
    print('[QuizPanel] Sound NOT FOUND: $raw (tried: $candidates)');
    await add(
      TextComponent(
        text: 'Sound not found:\n$raw',
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(color: ui.Color(0xFFEF4444), fontSize: 12),
        ),
        position: Vector2(_leftW / 2, _panelY + _panelH / 2),
        priority: priority + 3,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (game.size.isZero()) {
      print('[QuizPanel] Error: game.size is zero');
      return;
    }

    size = game.size;
    position = Vector2.zero();

    final w = size.x;
    final h = size.y;
    _panelH = h * panelHeightRatio;
    _panelY = h - _panelH;

    // backgrd - using 9-slice sprite
    await add(
      NineSliceSprite(
        assetPath: 'assets/9-Slice/',
        sliceSize: 64.0, // border thickness of the 9-slice
        position: Vector2(0, _panelY),
        size: Vector2(w, _panelH),
        priority: priority,
      ),
    );

    // define inner content area inside the panel
    _border = 64.0;
    _pad = 15.0;
    _innerTop = _panelY + _border + _pad;
    _innerBottom = _panelY + _panelH - _border - _pad;
    _innerH = _innerBottom - _innerTop;
    _innerSidePad = _border + _pad; // left/right padding inside panel

    _leftW = w * 0.5;
    final rightX = _leftW;

    // LEFT column theo type
    final type = (question.type).toLowerCase();
    final hasImage = (question.image ?? '').trim().isNotEmpty;
    final hasSound = (question.sound ?? '').trim().isNotEmpty;

    if (type == 'text') {
      await _addCenteredText(question.prompt);
    } else if (type == 'image') {
      if (hasImage) await _addImageCentered((question.image!).trim());
    } else if (type == 'imagesound' || type == 'image_sound') {
      await _addImageSound(
        imageRaw: hasImage ? (question.image!).trim() : null,
        soundRaw: hasSound ? (question.sound!).trim() : null,
      );
    } else if (type == 'sound') {
      if (hasSound) await _addSoundButtonCentered((question.sound!).trim());
    } else if (type == 'sound_fill') {
      if (hasSound) {
        await _addSoundFill(
          prompt: question.prompt,
          soundRaw: (question.sound!).trim(),
        );
      } else {
        await _addCenteredText(question.prompt);
      }
    } else {
      await _addCenteredText(question.prompt);
    }
    if (hasSound && !_autoPlayed) {
      _autoPlayed = true;
      // delay 100–150ms cho UI mounted
      Future.delayed(const Duration(milliseconds: 120), () {
        _playSoundRaw((question.sound!).trim());
      });
    }

    // RIGHT column
    final double gap = 8.0;
    final count = min(
      question.options.length,
      4,
    ); // Fixed: Using dart:math's min

    final innerW =
        (size.x - _leftW) -
        2 * _innerSidePad; // right column width inside right border
    final startX =
        rightX + _innerSidePad; // right column start inside right border
    double rowY = _innerTop;
    final rowH = (_innerH - gap * (count - 1)) / count;

    for (int i = 0; i < count; i++) {
      final displayLabel = '${i + 1}. ${question.options[i]}';
      await add(
        _AnswerItem(
          rect: ui.Rect.fromLTWH(startX, rowY, innerW, rowH),
          label: displayLabel,
          priority: priority + 3,
          onTap: () {
            if (_disabled) return;
            _disabled = true;
            onAnswer(i == question.correctIndex);
          },
        ),
      );
      rowY += rowH + gap;
    }
  }

  Future<void> _addCenteredText(String text) async {
    await add(
      TextComponent(
        text: text,
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: ui.Color(0xFFF1F5F9),
            fontSize: 18,
            height: 1.25,
          ),
        ),
        position: Vector2(_leftW / 2, _innerTop),
        priority: priority + 2,
        size: Vector2(_leftW - (_innerSidePad + _pad), _innerH / 2),
      ),
    );
  }

  Future<void> _addImageCentered(String imageRaw) async {
    final img = await _loadUiImage(imageRaw);
    if (img == null) {
      await add(
        TextComponent(
          text: 'Image not found:\n$imageRaw',
          anchor: Anchor.topCenter,
          textRenderer: TextPaint(
            style: const TextStyle(color: ui.Color(0xFFEF4444), fontSize: 12),
          ),
          position: Vector2(_leftW / 2, _innerTop),
          priority: priority + 2,
        ),
      );
      return;
    }

    final maxW = _leftW - (_innerSidePad + _pad);
    final maxH = _innerH / 2;
    final aspect = img.width / img.height;

    double w = maxW;
    double h = w / aspect;
    if (h > maxH) {
      h = maxH;
      w = h * aspect;
    }

    await add(
      _RoundedImage(
        image: img,
        radius: 12,
        size: Vector2(w, h),
        anchor: Anchor.topCenter,
        position: Vector2(_leftW / 2, _innerTop),
        priority: priority + 2,
      ),
    );
  }

  Future<void> _addImageSound({String? imageRaw, String? soundRaw}) async {
    const btnH = 32.0;
    const btnW = 140.0;
    const btnGapBottom = 15.0;

    if (soundRaw != null && soundRaw.isNotEmpty) {
      await add(
        _SmallButton(
          label: '🔊 Phát âm',
          onPressed: () => _playSoundRaw(soundRaw),
          position: Vector2((_leftW - btnW) / 2, _innerTop),
        )..size = Vector2(btnW, btnH),
      );
    }

    if (imageRaw == null || imageRaw.isEmpty) return;

    final img = await _loadUiImage(imageRaw);
    if (img == null) {
      await add(
        TextComponent(
          text: 'Image not found:\n$imageRaw',
          anchor: Anchor.topLeft,
          textRenderer: TextPaint(
            style: const TextStyle(color: ui.Color(0xFFEF4444), fontSize: 12),
          ),
          position: Vector2(_innerSidePad, _innerTop + btnH + btnGapBottom),
          priority: priority + 2,
        ),
      );
      return;
    }

    final imageAreaTop = _innerTop + btnH + btnGapBottom;
    final imageAreaBottom = _innerBottom;
    final imageAreaH = (imageAreaBottom - imageAreaTop).clamp(40.0, _innerH);

    final maxW = _leftW - (_innerSidePad + _pad);
    final maxH = imageAreaH;
    final aspect = img.width / img.height;

    double w = maxW;
    double h = w / aspect;
    if (h > maxH) {
      h = maxH;
      w = h * aspect;
    }

    final centerY = imageAreaTop + imageAreaH / 2;

    await add(
      _RoundedImage(
        image: img,
        radius: 12,
        size: Vector2(w, h),
        anchor: Anchor.center,
        position: Vector2(_leftW / 2, centerY),
        priority: priority + 2,
      ),
    );
  }

  Future<void> _addSoundButtonCentered(String raw) async {
    const btnW = 160.0;
    const btnH = 40.0;
    final pos = Vector2(_leftW / 2 - btnW / 2, _innerTop);
    await add(
      _SmallButton(
        label: '🔊 Phát âm',
        onPressed: () => _playSoundRaw(raw),
        position: pos,
      )..size = Vector2(btnW, btnH),
    );
  }

  Future<void> _addSoundFill({
    required String prompt,
    required String soundRaw,
  }) async {
    const btnH = 32.0;
    const btnW = 140.0;
    const btnGapBottom = 15.0;

    await add(
      _SmallButton(
        label: '🔊 Phát âm',
        onPressed: () => _playSoundRaw(soundRaw),
        position: Vector2((_leftW - btnW) / 2, _innerTop),
      )..size = Vector2(btnW, btnH),
    );

    final textAreaTop = _innerTop + btnH + btnGapBottom;
    final textAreaBottom = _innerBottom;
    final textAreaH = (textAreaBottom - textAreaTop).clamp(40.0, _innerH);
    final centerY = textAreaTop + textAreaH / 2;

    await add(
      TextComponent(
        text: prompt,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: ui.Color(0xFFF1F5F9),
            fontSize: 18,
            height: 1.25,
          ),
        ),
        position: Vector2(_leftW / 2, centerY),
        priority: priority + 2,
        size: Vector2(_leftW - (_innerSidePad + _pad), textAreaH),
      ),
    );
  }
}

class _RoundedImage extends PositionComponent {
  final ui.Image image;
  final double radius;

  _RoundedImage({
    required this.image,
    required this.radius,
    required super.size,
    required super.anchor,
    required super.position,
    required super.priority,
  });

  @override
  void render(ui.Canvas canvas) {
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(rrect);
    final src = ui.Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, rect, ui.Paint());
    canvas.restore();

    final border = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const ui.Color(0x22FFFFFF);
    canvas.drawRRect(rrect, border);
  }
}

class _SmallButton extends PositionComponent with TapCallbacks {
  final String label;
  final VoidCallback onPressed;

  _SmallButton({
    required this.label,
    required this.onPressed,
    required Vector2 position,
  }) : super(position: position, size: Vector2(112, 28), priority: 100004);

  bool _down = false;

  @override
  void render(ui.Canvas canvas) {
    final r = ui.RRect.fromRectAndRadius(
      size.toRect(),
      const ui.Radius.circular(10),
    );
    final fill = ui.Paint()
      ..color = _down ? const ui.Color(0xFF2A3647) : const ui.Color(0xFF3B4A60);
    canvas.drawRRect(r, fill);

    final border = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const ui.Color(0x33FFFFFF);
    canvas.drawRRect(r, border);

    final tp = TextPaint(
      style: const TextStyle(color: ui.Color(0xFFF8FAFC), fontSize: 14),
    );
    tp.render(canvas, label, size / 2, anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent e) => _down = true;
  @override
  void onTapCancel(TapCancelEvent e) => _down = false;
  @override
  void onTapUp(TapUpEvent e) {
    _down = false;
    onPressed();
  }
}

class _AnswerItem extends PositionComponent with TapCallbacks {
  final String label;
  final VoidCallback onTap;

  _AnswerItem({
    required ui.Rect rect,
    required this.label,
    required int priority,
    required this.onTap,
  }) : super(
         position: Vector2(rect.left, rect.top),
         size: Vector2(rect.width, rect.height),
         anchor: Anchor.topLeft,
         priority: priority,
       );

  bool _down = false;

  @override
  void render(ui.Canvas canvas) {
    final rrect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      const ui.Radius.circular(12),
    );

    final fill = ui.Paint()
      ..color = _down ? const ui.Color(0xFF2A3647) : const ui.Color(0xFF233042);
    canvas.drawRRect(rrect, fill);

    final border = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const ui.Color(0x33FFFFFF);
    canvas.drawRRect(rrect, border);

    final tp = TextPaint(
      style: const TextStyle(color: ui.Color(0xFFE2E8F0), fontSize: 16),
    );
    tp.render(
      canvas,
      label,
      Vector2(12, size.y / 2),
      anchor: Anchor.centerLeft,
    );
  }

  @override
  void onTapDown(TapDownEvent e) => _down = true;
  @override
  void onTapCancel(TapCancelEvent e) => _down = false;
  @override
  void onTapUp(TapUpEvent e) {
    _down = false;
    onTap();
  }
}
