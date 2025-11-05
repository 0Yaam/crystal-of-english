import 'dart:convert';
import 'package:mygame/components/Menu/flashcard/business/Deck.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'file_picker_stub.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:archive/archive.dart' as archive;
import 'package:flutter_archive/flutter_archive.dart';
import 'flashCard_Mapper.dart';
import 'package:flutter/services.dart' show rootBundle;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = await getDatabasesPath();
    String databasePath = join(path, 'learning_card.db');
    final db = await openDatabase(
      databasePath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    try {
      final pragma = await db.rawQuery("PRAGMA table_info(cards)");
      final existing = <String>{};
      for (final row in pragma) {
        final name = row['name'] as String?;
        if (name != null) existing.add(name);
      }

      final Map<String, String> expected = {
        'complexity': 'ALTER TABLE cards ADD COLUMN complexity INTEGER DEFAULT 1',
        'synonyms': 'ALTER TABLE cards ADD COLUMN synonyms TEXT',
        'defSound': 'ALTER TABLE cards ADD COLUMN defSound TEXT',
        'usageSound': 'ALTER TABLE cards ADD COLUMN usageSound TEXT',
      };

      for (final entry in expected.entries) {
        if (!existing.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('Added missing column `${entry.key}` to cards table at runtime');
          } catch (e) {
            print('Failed to add column ${entry.key}: $e');
          }
        }
      }
    } catch (e) {
      print('Runtime schema reconciliation failed: $e');
    }

    return db;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE cards ADD COLUMN complexity INTEGER DEFAULT 1',
        );
      } catch (e) {
        print('onUpgrade: add complexity failed or already applied: $e');
      }
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      create table decks (
        id integer primary key,
        name text not null,
        description text,
        created_at integer,
        updated_at integer,
        media text
      )
''');

    await db.execute('''
      create table cards(
        id integer primary key,
        created_at integer,
        updated_at integer,
        deck_id integer,
        word text,
        meaning text,
        img text,
        synonyms text,
        sound text,
        defSound text,
        usageSound text,
        example text,
        ipa text,
        complexity  int default 1,
        interval integer,
        reps integer,
        due integer,
        last_review integer,
        lapses integer,
        ease_factor real,
        foreign key (deck_id) references decks (id) on delete cascade
      )
''');
  }

  Future<int> insertDeck(Deck deck) async {
    final db = await database;
    return await db.insert(
      'decks',
      deck.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Deck>> getDecks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('decks');
    return List.generate(maps.length, (i) {
      return Deck.fromMap(maps[i]);
    });
  }

  
  Future<void> deleteDeck(int id) async {
    final db = await database;
    await db.delete('decks', where: 'id=?', whereArgs: [id]);
    await db.delete('cards', where: 'deck_id=?', whereArgs: [id]);
  }

  Future<List<Flashcard>> getCardForDeck(int deckId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'deck_id=?',
      whereArgs: [deckId],
    );
    return List.generate(maps.length, (i) {
      return Flashcard.fromMap(maps[i]);
    });
  }

  Future<List<Flashcard>> getCardByLevel(int level) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'level=?',
      whereArgs: [level],
    );
    return List.generate(maps.length, (i) {
      return Flashcard.fromMap(maps[i]);
    });
  }

  Future<void> updateCard(Flashcard card) async {
    final db = await database;
    await db.update(
      'cards',
      {
        'due_date': card.due!.toIso8601String(),
      },
      where: 'id=?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteCard(int cardId) async {
    final db = await database;
    await db.delete('cards', where: 'id=?', whereArgs: [cardId]);
  }

  Future<int> insertCard(Flashcard card) async {
    final db = await database;
    return await db.insert(
      'cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> pickApkgFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apkg'],
    );
    if (result != null) {
      return result.files.single.path;
    } else {
      return null;
    }
  }

  Future<String?> pickAndCopyFile() async {
    final pickedFile = await pickApkgFile();
    if (pickedFile == null || pickedFile.isEmpty) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final savedPath = join(appDir.path, basename(pickedFile));
    await File(pickedFile).copy(savedPath);
    return savedPath;
  }

  Future<String?> unzipApkgFile(String apkgFilePath) async {
    if (apkgFilePath.isEmpty) return null;
    final file = File(apkgFilePath);
    final bytes = await file.readAsBytes();

    final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;

    final outputDir = await CreateUnZipFolder();

    try {
      await ZipFile.extractToDirectory(
        zipFile: file,
        destinationDir: outputDir,
        onExtracting: (zipEntry, progress) {
          return ZipFileOperation.includeItem;
        },
      );
    } catch (e) {
      print(e);
    }

    for (final file in zipArchive) {
      if (file.name == 'collection.anki21') {
        final data = file.content as List<int>;
        final dbPath = '$tempPath/collection.anki21';
        final newFile = File(dbPath);
        await newFile.writeAsBytes(data);
        return dbPath;
      }
    }
    return null;
  }

  Future<Directory> CreateUnZipFolder() async {
    final dir = await getApplicationDocumentsDirectory();
    final myAppFolder = Directory('${dir.path}/anki');
    if (!myAppFolder.existsSync()) {
      myAppFolder.createSync();
      print("init folder anki at ${myAppFolder.path}");
    }
    final outputDir = Directory('${dir.path}/anki/unzipAnki');
    if (!outputDir.existsSync()) {
      outputDir.createSync();
      print("Create new folder at ${outputDir.path}");
    }
    return outputDir;
  }

  Future<Directory> CreateDeckFolder() async {
    final dir = await getApplicationDocumentsDirectory();

    final folderName = DateTime.now().millisecondsSinceEpoch.toString();
    final outputDir = Directory('${dir.path}/anki/$folderName');
    if (!outputDir.existsSync()) {
      outputDir.createSync();
      print("Create new folder at ${outputDir.path}");
    }
    return outputDir;
  }

  Future<void> importDataFromAnki(String ankiDbPath) async {
    final ankiDb = await openDatabase(ankiDbPath);
    final jsonDeck = await ankiDb.rawQuery(' select decks from col c ');
    final String deckString = jsonDeck.first['decks'] as String;
    final Map<String, dynamic> deckMap =
        jsonDecode(deckString) as Map<String, dynamic>;

    final folderName = await MoveMediaFile();

    for (final deck in deckMap.entries) {
      {
        final deckId = int.parse(deck.key);
        if (deckId == 1) continue;
        final deckName = deck.value['name'] as String;
        Deck newDeck = Deck(name: deckName, media: folderName);
        final int myDeckId = await insertDeck(newDeck);
        await processCardForDeck(ankiDb, deckId, myDeckId);
      }
    }
    await ankiDb.close();
  }

  Future<void> processCardForDeck(
    Database ankiDb,
    int ankiDeckId,
    int deckId,
  ) async {
    final cards = await ankiDb.rawQuery(
      '''
        SELECT DISTINCT
          n.id AS note_id,
          c.did AS deck_id,
          n.flds ,
          n.mid
        FROM notes AS n
        JOIN cards AS c
        ON n.id = c.nid
        where c.did=?
''',
      [ankiDeckId],
    );

    for (final row in cards) {
      print("model :${row['mid']}");
      final newCard = mapRowToFlashcard(row, deckId);
      if (newCard != null) {
        insertCard(newCard);
      }
    }
  }

  Future<String> MoveMediaFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaFile = File('${dir.path}/anki/unzipAnki/media');
    if (!mediaFile.existsSync()) {
      throw Exception("Khong tim thay media trong unzip");
    }

    final mediaJsonStr = await mediaFile.readAsString();
    final Map<String, dynamic> mediaMapRaw = jsonDecode(mediaJsonStr);

    final mediaMap = mediaMapRaw.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    final outputDir = await CreateUnZipFolder();
    Directory deckDir = await CreateDeckFolder();
    try {
      for (final entry in mediaMap.entries) {
        final oldFile = File('${dir.path}/anki/unzipAnki/${entry.key}');
        if (oldFile.existsSync()) {
          final newFile = File('${deckDir.path}/${entry.value}');
          await oldFile.copy(newFile.path);
        } else {
          print('cant find ${oldFile.path}');
        }
      }

      try {
        await outputDir.delete(recursive: true);
        print("clean unzip ${outputDir.path}");
      } catch (e) {
        print("delete bug $e");
      }
    } catch (e) {
      print('import bug $e');
    }
    final folderName = basename(deckDir.path);
    return folderName;
  }

  Future<String?> getMediaFile(int deckID) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      select media
      from decks
      where id=?
''',
      [deckID],
    );
    if (result.isNotEmpty) {
      return result.first['media'] as String?;
    }
    return null;
  }
  Future<void> importFromAssetApkg(String assetPath) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath = join(tmpDir.path, 'demo.apkg');
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await File(outPath).writeAsBytes(bytes, flush: true);
    final dbPath = await unzipApkgFile(outPath);
    if (dbPath == null) return;
    await importDataFromAnki(dbPath);
  }

  Future<List<Map<String, Object?>>> getCardsTableInfo() async {
    final db = await database;
    final info = await db.rawQuery('PRAGMA table_info(cards)');
    return List<Map<String, Object?>>.from(info);
  }

  Future<void> deleteLearningCardDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, 'learning_card.db');
      await deleteDatabase(dbPath);
      _database = null;
      print('Deleted learning_card.db at $dbPath');
    } catch (e) {
      print('Failed to delete learning_card.db: $e');
    }
  }
}
