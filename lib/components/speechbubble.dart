import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

class SpeechBubble extends PositionComponent {
  final String text;
  final double minWidth;
  final double maxWidth;
  final double padding;
  final double gapToHead;
  final TextPaint textPaint;
  PositionComponent? target;

  final double cornerRadius = 5;
  final double borderWidth = 1;
  final double tailH = 8.0;
  final double tailW = 12.0;

  late final TextPainter _painter;

  SpeechBubble({
    required this.text,
    this.target,
    this.minWidth = 48,
    this.maxWidth = 140,
    this.padding = 6,
    this.gapToHead = 0,
    TextPaint? textPaint,
  })  : textPaint = textPaint ??
            TextPaint(
              style: const TextStyle(
                fontFamily: 'MyFont', 
                fontSize: 7,
                color: Color.fromARGB(255, 53, 53, 53),
                height: 1.2,
              ),
            ),
        super(anchor: Anchor.bottomCenter, priority: 100);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _painter = textPaint.toTextPainter(text)..layout(maxWidth: maxWidth);
    final contentW = _painter.width, contentH = _painter.height;
    final boxW = (contentW + padding * 2).clamp(minWidth, double.infinity);
    final boxH = contentH + padding * 2;
    size = Vector2(boxW, boxH);
    _follow();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _follow();
  }

  void _follow() {
    final t = target;
    if (t == null || !t.isMounted) return;
    position = t.position + Vector2(0, -t.size.y / 2 - gapToHead);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(5),
    );

    final bg = Paint()..color = const Color.fromARGB(255, 235, 232, 232);
    final border = Paint()
      ..color = const Color.fromARGB(255, 66, 66, 66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rect, bg);
    canvas.drawRRect(rect, border);

    final cx = size.x / 2;
    final tail = Path()
      ..moveTo(cx - tailW / 2, size.y)
      ..lineTo(cx + tailW / 2, size.y)
      ..lineTo(cx, size.y + tailH)
      ..close();
    canvas.drawPath(tail, bg);
    canvas.drawPath(tail, border);

    _painter.paint(
      canvas,
      Offset(padding.floorToDouble(), padding.floorToDouble()),
    );
  }
}
