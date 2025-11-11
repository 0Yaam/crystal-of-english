import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class QuizQuestion {
  final String id;
  final String topic;
  final String type;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? sound;
  final String? image;

  const QuizQuestion({
    required this.id,
    required this.topic,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.sound,
    this.image,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> m, String topic) {
    return QuizQuestion(
      id: m['id'] as String,
      topic: topic,
      type: (m['type'] as String).toLowerCase(),
      prompt: m['prompt'] as String,
      options: (m['options'] as List).map((e) => e as String).toList(),
      correctIndex: m['correctIndex'] as int,
      sound: m['sound'] as String?,
      image: m['image'] as String?,
    );
  }
}

class QuizRepository {
  Future<List<QuizQuestion>> loadTopic(String topic) async {
    final candidates = <String>[
      'assets/quiz/$topic/$topic.json',
      'assets/quiz/$topic/animals.json',
    ];

    String? raw;
    Object? lastErr;
    for (final path in candidates) {
      try {
        raw = await rootBundle.loadString(path);
        break;
      } catch (e) {
        lastErr = e;
      }
    }
    if (raw == null) {
      throw Exception('Cannot find JSON for topic "$topic". Last error: $lastErr');
    }

    final data = json.decode(raw) as Map<String, dynamic>;
    final list = (data['questions'] as List).cast<Map<String, dynamic>>();
    final questions = list.map((m) => QuizQuestion.fromMap(m, topic)).toList();


    questions.shuffle(Random());

    return questions;
  }
}
