import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class AreaTitle extends PositionComponent {
  final String title;
  final double _fadeIn = 0.35;
  final double _hold = 1.0;
  final double _fadeOut = 1.2;
  late TextComponent _text;
  late TextStyle _baseStyle;
  double _t = 0.0;
  bool _built = false;
  AreaTitle(this.title);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _baseStyle = const TextStyle(
      fontFamily: 'MyFont',
      fontSize: 42,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: [
        Shadow(offset: Offset( 1, 0), color: Colors.black),
        Shadow(offset: Offset(-1, 0), color: Colors.black),
        Shadow(offset: Offset( 0, 1), color: Colors.black),
        Shadow(offset: Offset( 0,-1), color: Colors.black),
      ],
    );
  }

  @override
  void onMount() {
    super.onMount();
    if (_built) return;
    _built = true;
    final viewportSize = (parent is PositionComponent)
        ? (parent as PositionComponent).size
        : Vector2.zero();

    _text = TextComponent(
      text: title,
      textRenderer: TextPaint(
        style: _baseStyle.copyWith(color: Colors.white.withOpacity(0)),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(viewportSize.x / 2, 50),
      priority: 10000,
    );

    size = viewportSize;
    add(_text);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_built) return;
    _t += dt;
    final total = _fadeIn + _hold + _fadeOut;
    double opacity;
    if (_t < _fadeIn) {
      opacity = (_t / _fadeIn).clamp(0.0, 1.0);
    } else if (_t < _fadeIn + _hold) {
      opacity = 1.0;
    } else if (_t < total) {
      final t2 = _t - _fadeIn - _hold;
      opacity = (1.0 - t2 / _fadeOut).clamp(0.0, 1.0);
    } else {
      removeFromParent();
      return;
    }

    final c = (_baseStyle.color ?? Colors.white).withOpacity(opacity);
    _text.textRenderer = TextPaint(style: _baseStyle.copyWith(color: c));
  }
  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    if (_built) {
      size = newSize;
      _text.position = Vector2(newSize.x / 2, _text.position.y);
    }
  }
}
