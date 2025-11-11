import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/flashcard/data/database_helper.dart';
import 'package:mygame/state/player_profile.dart';
import 'package:mygame/main.dart';
import 'package:flame/components.dart';

class SaveLoadScreen extends StatefulWidget {
  final MyGame? game;
  const SaveLoadScreen({super.key, this.game});

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  List<Map<String, Object?>> _slots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await DatabaseHelper.instance.listPlayerProfileSlots();
    setState(() {
      _slots = list;
      _loading = false;
    });
  }

  String _formatTimestamp(Object? t) {
    if (t == null) return 'Empty';
    try {
      final ms = (t as num).toInt();
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Map<String, Object?> _findSlot(int slot) {
    for (final s in _slots) {
      final v = s['slot'];
      if (v is int && v == slot) return s;
    }
    return {};
  }

  Future<void> _saveSlot(int slot) async {

    await PlayerProfile.instance.saveToSlot(slot);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to slot $slot')));
  }

  Future<void> _loadSlot(int slot) async {
    await PlayerProfile.instance.loadFromSlot(slot);
    final data = await DatabaseHelper.instance.loadPlayerProfileSlot(slot);

  if (widget.game != null && data != null) {
      final mapFile = data['map_file'] as String?;
      final px = (data['pos_x'] as num?)?.toDouble();
      final py = (data['pos_y'] as num?)?.toDouble();
      if (mapFile != null && px != null && py != null) {
        try {
          await widget.game!.loadMap(mapFile, spawn: Vector2(px, py));
        } catch (e) {
          debugPrint('Failed to move game to loaded slot: $e');
        }
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded slot $slot')));
    Navigator.of(context).pop();
  }

  Future<void> _deleteSlot(int slot) async {
    await DatabaseHelper.instance.deletePlayerProfileSlot(slot);
    await _refresh();
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save / Load'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: 3,
              itemBuilder: (c, i) {
                final slotId = i + 1;
                final slot = _findSlot(slotId);
                final savedAt = slot['saved_at'];
                final prof = slot['proficiency'];
                final pref = slot['preferred_deck'];
                return Card(
                  child: ListTile(
                    title: Text('Slot $slotId'),
                    subtitle: Text('Saved: ${_formatTimestamp(savedAt)}\nProficiency: ${prof ?? '-'}  Preferred deck: ${pref ?? '-'}'),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.save),
                          tooltip: 'Save to slot',
                          onPressed: () => _saveSlot(slotId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Load slot',
                          onPressed: () => _loadSlot(slotId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete slot',
                          onPressed: () => _deleteSlot(slotId),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
