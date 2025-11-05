import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final List<String> choices;
  final Function(int) onSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.choices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question,
              style: const TextStyle(color: Colors.white, fontSize: 30)),
            const SizedBox(height: 16),
            ...List.generate(choices.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // or other color per choice
                  ),
                  onPressed: () => onSelected(index),
                  child: Text(choices[index],
                    style: const TextStyle(color: Colors.white, fontSize: 23)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
