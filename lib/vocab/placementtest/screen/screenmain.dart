import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mygame/vocab/placementtest/library/placementtest.dart';
import 'package:mygame/vocab/placementtest/screen/endscreen.dart';
import 'package:mygame/vocab/placementtest/screen/quizscreen.dart';
import 'package:mygame/vocab/placementtest/screen/startscreen.dart';

class QuizApp extends StatefulWidget {
  const QuizApp({super.key});

  @override
  State<QuizApp> createState() => _QuizAppState();
}

class _QuizAppState extends State<QuizApp> {
  late List<QuizQuestion> _questions;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final raw = await rootBundle.loadString(
      'assets/quiz/placementtest/placementtest.json',
    );

    // decode ra List<dynamic>
    final jsonList = (json.decode(raw) as List).cast<Map<String, dynamic>>();

    setState(() {
      _questions = QuizQuestion.listFromJson(jsonList);
    });
  }

  void _startQuiz() {
    setState(() {
      _score = 0;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: _questions,
          onFinish: (int finalScore) {
            _onQuizEnd(finalScore); // nhận score thật
          },
        ),
      ),
    );
  }

  void _onQuizEnd(int finalScore) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EndScreen(
          score: finalScore,
          total: _questions.length,
          onRestart: _restartQuiz,
        ),
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _score = 0;
      _questions.shuffle(); // nếu muốn shuffle lại quiz
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: _questions,
          onFinish: (int finalScore) {
            _onQuizEnd(finalScore);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Placement Quiz',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(
          0xFF1E1E1E,
        ), // tông tối giống Duolingo
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  '📚 Placement Test',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Test your English level with this short quiz. '
                  'There are 15 questions designed to check your grammar, vocabulary, '
                  'and comprehension skills. Good luck!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _startQuiz,
                  child: const Text(
                    'Start Quizz',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
