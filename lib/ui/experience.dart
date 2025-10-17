import 'package:flutter/painting.dart' show TextStyle;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show EdgeInsets;

typedef LevelUpCallback = void Function(int newLevel);

class ExperienceBar extends PositionComponent {
  @override
  final double width;
  @override
  final double height;
  final EdgeInsets margin;
  final LevelUpCallback? onLevelUp;

  int level;
  int xp;  //tong exp hien tai
  int xpToNext;  // mốc cần để lên level kế

  ExperienceBar({
    this.width = 180,
    this.height = 12,
    this.margin = const EdgeInsets.only(left: 16, top: 56),
    this.level = 1,
    this.xp = 0,
    this.xpToNext = 50,
    this.onLevelUp,
    int priority = 100001,
  }) : super(priority: priority, anchor: Anchor.topLeft);

  // cách tính số exp tiếp 
  int _nextReqForLevel(int lv) {
    if (lv <= 1) return 50;
    return (50 + (lv - 1) * 25 + ((lv - 1) * 5));
  }

  void setLevel(int lv, {int currentXp = 0}) {
    level = lv.clamp(1, 9999);
    xpToNext = _nextReqForLevel(level);
    xp = currentXp.clamp(0, xpToNext - 1);
  }

  void addXp(int amount) {
    var add = amount;
    while (add > 0) {
      final remain = xpToNext - xp;
      if (add >= remain) {
        // lên level
        add -= remain;
        level += 1;
        xp = 0;
        xpToNext = _nextReqForLevel(level);
        onLevelUp?.call(level);
      } else {
        xp += add;
        add = 0;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    // khung
    final bgRect = ui.Rect.fromLTWH(
      margin.left.toDouble(),
      margin.top.toDouble(),
      width,
      height,
    );
    final r = ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(6));
    final bg = ui.Paint()..color = const ui.Color(0xFF1E293B);
    canvas.drawRRect(r, bg);

    // fill
    final pct = xpToNext == 0 ? 0.0 : (xp / xpToNext).clamp(0.0, 1.0);
    final fillRect = ui.Rect.fromLTWH(
      margin.left.toDouble(),
      margin.top.toDouble(),
      width * pct,
      height,
    );
    final fill = ui.Paint()..color = const ui.Color(0xFF22C55E);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(fillRect, const ui.Radius.circular(6)),
      fill,
    );

    // viền
    final border = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const ui.Color(0x66FFFFFF);
    canvas.drawRRect(r, border);

    final tp = TextPaint(
      style: const TextStyle(
        color: ui.Color(0xFFE2E8F0),
        fontSize: 10,
      ),
    );
    final text =
        'Lv $level   $xp/$xpToNext';
    tp.render(
      canvas,
      text,
      Vector2(margin.left + 4, margin.top - 12),
      anchor: Anchor.topLeft,
    );
  }
}
