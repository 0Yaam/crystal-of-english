
import 'package:flutter/widgets.dart';
import 'package:mygame/components/Menu/flashcard/data/database_helper.dart';


class Deck {
  final int? id;
  final String name;
  final String? description;
  DateTime? createdAt;
  DateTime? updatedAt;
  final String? media;

  Deck({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.media
  });
  Map<String,dynamic> toMap(){
    return{
      'id':id,
      'name':name,
      'description':description,
      'created_at':createdAt?.millisecondsSinceEpoch,
      'updated_at':updatedAt?.millisecondsSinceEpoch,
      'media':media
    };
  }
  factory Deck.fromMap(Map<String,dynamic> map){
    return Deck(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int) : null,
      updatedAt: map['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int) : null,
      media: map["media"] as String?
    );
  }

}
class Deckmodel with ChangeNotifier{
  static final _dbhelper=DatabaseHelper.instance;

  final List<Deck> _decks=[];
  List<Deck> get deck=>_decks;
  Future<void> fetchDecks() async{
    final data=await _dbhelper.getDecks();
    _decks.clear();
    _decks.addAll(
      data
    );
    notifyListeners();
  }


  Future<void> insertDeck(String name,{String? description}) async{
    Deck addDeck=Deck(name: name,description: description);
    int newId=await _dbhelper.insertDeck(addDeck);
    Deck newDeck=Deck(id: newId ,name: name,description: description);
    _decks.add(newDeck);
    await fetchDecks();
  }

  Future<void> deleteDeck(int id) async{
    await _dbhelper.deleteDeck(id);
    _decks.removeWhere((d)=>d.id==id);
    notifyListeners();
  }
  Future<void> filePicker()async{
    final filePath = await _dbhelper.pickAndCopyFile();
    if (filePath == null || filePath.isEmpty) {


      try {
        await (DatabaseHelper.instance as dynamic)
            .importFromAssetApkg('assets/anki-deck/IELTS - Advanced__Unit 02 - Time for a change.apkg');
      } catch (_) {
        return;
      }
    } else {
      final ankiDbPath = await _dbhelper.unzipApkgFile(filePath);
      if (ankiDbPath == null || ankiDbPath.isEmpty) {
        return;
      }
      await _dbhelper.importDataFromAnki(ankiDbPath);
    }
    await fetchDecks();
  }

  Future<String?> getMediaFile(int id) async{
    final String? result= await _dbhelper.getMediaFile(id);
    return result;
  }
}
