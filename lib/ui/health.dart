import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Health extends PositionComponent {
  final int maxHearts;
  int _currentHearts;
  final String fullHeartAsset;
  final String emptyHeartAsset;
  final double heartSize;
  final double spacing;
  final EdgeInsets margin;

  final List<SpriteComponent> _icons = [];
  Sprite? _fullSprite;
  Sprite? _emptySprite;

  Health({
    required this.maxHearts,
    int? currentHearts,
    required this.fullHeartAsset,
    required this.emptyHeartAsset,
    this.heartSize = 26,
    this.spacing = 6,
    this.margin = const EdgeInsets.only(left: 16, top: 16),
    int priority = 100001,
  })  : _currentHearts = currentHearts ?? maxHearts,
        super(priority: priority, anchor: Anchor.topLeft);
  int get currentHearts => _currentHearts;

  @override
  Future<void> onLoad() async {
    await super.onLoad();


    _fullSprite = await Sprite.load(fullHeartAsset);
    _emptySprite = await Sprite.load(emptyHeartAsset);


    for (var i = 0; i < maxHearts; i++) {
      final icon = SpriteComponent(
        sprite: _emptySprite,
        size: Vector2.all(heartSize),
        anchor: Anchor.topLeft,
        position: Vector2(
          margin.left + i * (heartSize + spacing),
          margin.top,
        ),
        priority: priority,
      );
      _icons.add(icon);
      add(icon);
    }
    _refreshVisual();
  }


  void setCurrent(int value) {
    _currentHearts = value.clamp(0, maxHearts);
    _refreshVisual();
  }

  void damage([int hearts = 1]) {
    setCurrent(_currentHearts - hearts);
  }

  void heal([int hearts = 1]) {
    setCurrent(_currentHearts + hearts);
  }

  void refill() {
    setCurrent(maxHearts);
  }

  bool get isDead => _currentHearts <= 0;

  void _refreshVisual() {
    if (_fullSprite == null || _emptySprite == null) return;
    for (var i = 0; i < maxHearts; i++) {
      _icons[i].sprite = i < _currentHearts ? _fullSprite : _emptySprite;
    }
  }
}
