import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'package:mygame/components/Menu/flashcard/data/findComplexity.dart';

Flashcard? mapRowToFlashcard(Map<String, Object?> row, int deckId) {
  final imgRegex = RegExp(r'<img\s+src="([^"]+)"');
  final soundRegex = RegExp(r'\[sound:([^\]]+)\]');
  final tagRegex = RegExp(r'<[^>]+>');
  final ipaRegex = RegExp(r'(?<=\/)[^/]+(?=\/)');

  final flds = row['flds'] as String;
  final List<String> fields = flds.split('\x1f');

  switch (row['mid'] as int) {
    case 1470756627995:
      final meaningRG = fields[3]
          .replaceAll(tagRegex, '')
          .replaceAll('&nbsp;', '\n');
      final exampleRG = fields[4].replaceAll(tagRegex, '');
      final soundPath = soundRegex.firstMatch(fields[2])?.group(1);
      final imagePath = imgRegex.firstMatch(fields[5])?.group(1);
      final synonymsPath = imgRegex.firstMatch(fields[6])?.group(1);
      final ipaMatch = ipaRegex.firstMatch(fields[1])?.group(0);


      final word = fields[0].replaceAll(tagRegex, '');
      if (fields.length == 7) {
        Flashcard newCard = Flashcard(
          deckId: deckId,

          word: word,
          ipa: ipaMatch,
          sound: soundPath,
          meaning: meaningRG,
          example: exampleRG,

          due: DateTime.now(),

          img: imagePath,
          synonyms: synonymsPath,
          complexity: findComplexity(word),
        );
        return newCard;
      }

      break;
    case 1434531251879:
      final imagePath = imgRegex.firstMatch(fields[1])?.group(1);
      final defSoundPath = soundRegex.firstMatch(fields[3])?.group(1);
      final usageSoundPath = soundRegex.firstMatch(fields[4])?.group(1);
      final soundPath = soundRegex.firstMatch(fields[2])?.group(1);
      final word = fields[0].replaceAll(tagRegex, '');
      if (fields.length == 8) {
        Flashcard newCard = Flashcard(
          deckId: deckId,
          word: word,
          meaning: fields[5],
          example: fields[6],
          ipa: fields[7].replaceAll(tagRegex, ""),
          due: DateTime.now(),
          defSound: defSoundPath,
          usageSound: usageSoundPath,
          img: imagePath,
          sound: soundPath,
          complexity: findComplexity(word),
        );
        return newCard;
      }
      break;
    case 3:

      break;
    default:
      print(
        "Unknown model id: ${row['mid']}. Skipping card. Please tell admin to update the mapping function.",
      );
      return null;
  }

  return null;
}

