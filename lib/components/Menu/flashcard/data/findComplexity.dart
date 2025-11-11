


bool checkSuffix(String word) {
  final suffix = ['tion', 'ology', 'sion', 'phobia'];
  for (var suf in suffix) {
    if (word.endsWith(suf) && word.length >= suf.length + 2) {
      return true;
    }
  }
  final prefix = ['un','im', 'dis', 'non', 'pre', 'mis', 'sub', 'inter'];
  for (var pre in prefix) {
    if (word.startsWith(pre) && word.length > pre.length + 2) {
      return true;
    }
  }
  return false;
}

int countSyllables(String word) {
  word = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  if (word.isEmpty) return 0;

  if (word.endsWith('e')) {
    word = word.substring(0, word.length - 1);
  }

  final vowels = 'aeiouy';
  int count = 0;
  bool prevVowel = false;

  for (int i = 0; i < word.length; i++) {
    if (vowels.contains(word[i])) {
      if (!prevVowel) {
        count++;
        prevVowel = true;
      }
    } else {
      prevVowel = false;
    }
  }


  return count > 0 ? count : 1;
}

int findLengthRule(String word) {
  if (word.contains('-') || word.contains(' ')) {
    return 0;
  }

  if (word.length <= 3) {
    return 1;
  } else if (word.length < 5) {
    return 2;
  } else if (word.length < 7) {
    return 3;
  } else if (word.length < 9) {
    return 4;
  } else if (word.length < 11) {
    return 5;
  } else if (word.length < 15) {
    return 6;
  } else {
    return 7;
  }
}

int findComplexity(String word) {
  int rule = findLengthRule(word);
  int syllables = countSyllables(word);
  int hasSuffix = checkSuffix(word) ? 1 : 0;

  int complexity = (syllables * 0.7 + rule * 0.3).round() + hasSuffix;
  return complexity;
}
