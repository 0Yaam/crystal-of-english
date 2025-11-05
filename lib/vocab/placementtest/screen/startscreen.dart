import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          ),
          onPressed: onStart,
          child: const Text('Start Quiz',
            style: TextStyle(fontSize: 24, color: Colors.black)),
        ),
      ),
    );
  }
}
