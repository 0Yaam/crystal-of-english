import 'package:flutter/foundation.dart';
import 'package:mygame/components/Menu/flashcard/data/database_helper.dart';






class PlayerProfile {
  int? _proficiencyLevel;
  int? _preferredDeckLevel;
  String? _mapFile;
  double? _posX;
  double? _posY;
  int? _hearts;
  int? _xp;
  int? _gold;
  String? _inventoryJson;

  final int _autosaveSlot = 1;

  static final PlayerProfile instance = PlayerProfile._();

  PlayerProfile._();


  Future<void> init() async {
    try {
      final row = await DatabaseHelper.instance.loadPlayerProfileSlot(_autosaveSlot);
      if (row != null) {
        _proficiencyLevel = (row['proficiency'] as num?)?.toInt();
        _preferredDeckLevel = (row['preferred_deck'] as num?)?.toInt();
        _mapFile = row['map_file'] as String?;
        _posX = (row['pos_x'] as num?)?.toDouble();
        _posY = (row['pos_y'] as num?)?.toDouble();
        _hearts = (row['hearts'] as num?)?.toInt();
        _xp = (row['xp'] as num?)?.toInt();
        _gold = (row['gold'] as num?)?.toInt();
        _inventoryJson = row['inventory'] as String?;
      }
    } catch (e) {

      debugPrint('PlayerProfile.init load failed: $e');
    }
  }

  int? get proficiencyLevel => _proficiencyLevel;
  int? get preferredDeckLevel => _preferredDeckLevel;
  String? get mapFile => _mapFile;
  double? get posX => _posX;
  double? get posY => _posY;
  int? get hearts => _hearts;
  int? get xp => _xp;
  int? get gold => _gold;

  Future<void> setProficiencyLevel(int level, {bool autosave = true}) async {
    _proficiencyLevel = level;
    if (autosave) await _autosave();
  }

  Future<void> setPreferredDeckLevel(int level, {bool autosave = true}) async {
    _preferredDeckLevel = level;
    if (autosave) await _autosave();
  }


  Future<void> saveToSlot(int slot) async {
    await DatabaseHelper.instance.savePlayerProfileSlot(
      slot,
      proficiency: _proficiencyLevel,
      preferredDeck: _preferredDeckLevel,
      mapFile: _mapFile,
      posX: _posX,
      posY: _posY,
      hearts: _hearts,
      xp: _xp,
      gold: _gold,
      inventoryJson: _inventoryJson,
      extra: null,
    );
  }

  Future<void> loadFromSlot(int slot) async {
    final row = await DatabaseHelper.instance.loadPlayerProfileSlot(slot);
    if (row == null) return;
    _proficiencyLevel = (row['proficiency'] as num?)?.toInt();
    _preferredDeckLevel = (row['preferred_deck'] as num?)?.toInt();
    _mapFile = row['map_file'] as String?;
    _posX = (row['pos_x'] as num?)?.toDouble();
    _posY = (row['pos_y'] as num?)?.toDouble();
    _hearts = (row['hearts'] as num?)?.toInt();
    _xp = (row['xp'] as num?)?.toInt();
    _gold = (row['gold'] as num?)?.toInt();
    _inventoryJson = row['inventory'] as String?;
  }


  Future<void> saveSnapshot({
    String? mapFile,
    double? posX,
    double? posY,
    int? hearts,
    int? xp,
    int? gold,
    String? inventoryJson,
    int slot = 1,
  }) async {
    if (mapFile != null) _mapFile = mapFile;
    if (posX != null) _posX = posX;
    if (posY != null) _posY = posY;
    if (hearts != null) _hearts = hearts;
    if (xp != null) _xp = xp;
    if (gold != null) _gold = gold;
    if (inventoryJson != null) _inventoryJson = inventoryJson;

    await DatabaseHelper.instance.savePlayerProfileSlot(
      slot,
      proficiency: _proficiencyLevel,
      preferredDeck: _preferredDeckLevel,
      mapFile: _mapFile,
      posX: _posX,
      posY: _posY,
      hearts: _hearts,
      xp: _xp,
      gold: _gold,
      inventoryJson: _inventoryJson,
      extra: null,
    );
  }

  Future<void> _autosave() async {
    try {
      await saveToSlot(_autosaveSlot);
    } catch (e) {
      debugPrint('PlayerProfile autosave failed: $e');
    }
  }



  int effectiveLevel() {
    return _preferredDeckLevel ?? _proficiencyLevel ?? 1;
  }
}
