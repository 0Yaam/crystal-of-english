import 'package:flutter/material.dart';

class GameItem {
  final String name;
  final IconData icon;
  const GameItem(this.name, this.icon);
}

class Inventory extends ChangeNotifier {
  Inventory._();
  static final Inventory instance = Inventory._();

  int capacity = 20;
  final List<GameItem> _items = <GameItem>[];

  List<GameItem> get items => List.unmodifiable(_items);

  bool add(GameItem item) {
    if (_items.length >= capacity) return false;
    _items.add(item);
    notifyListeners();
    return true;
  }

  bool remove(GameItem item) {
    final ok = _items.remove(item);
    if (ok) notifyListeners();
    return ok;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

