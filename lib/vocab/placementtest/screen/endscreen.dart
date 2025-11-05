import 'package:flutter/material.dart';

class EndScreen extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;

  const EndScreen({
    super.key,
    required this.score,
    required this.total,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    double percent = (score / total);
    int percentInt = (percent * 100).toInt();

    // Mapping % → IELTS band & tip
    String band;
    String tip;
    Color gradeColor;
    if (percent >= 0.85) {
      band = "Band 8-9 / C1+";
      tip = "Excellent! Focus on advanced grammar and complex vocabulary.";
      gradeColor = Colors.greenAccent;
    } else if (percent >= 0.7) {
      band = "Band 7 / B2+";
      tip = "Good! Improve accuracy and fluency in writing & speaking.";
      gradeColor = Colors.tealAccent;
    } else if (percent >= 0.5) {
      band = "Band 5-6 / B1";
      tip = "Fair. Work on grammar basics and expand vocabulary.";
      gradeColor = Colors.orangeAccent;
    } else {
      band = "Band 3-4 / A2-B1";
      tip = "Needs improvement. Focus on simple sentences and core vocabulary.";
      gradeColor = Colors.redAccent;
    }

    // Example skill analysis
    final Map<String, String> skillAnalysis = {
      "Listening": percent >= 0.7 ? "Strong" : "Weak",
      "Reading": percent >= 0.5 ? "Average" : "Weak",
      "Writing": percent >= 0.7 ? "Good" : "Needs Practice",
      "Speaking": percent >= 0.85 ? "Excellent" : "Practice Needed",
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side: main info
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Finished',
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Score: $score / $total (${percentInt}%)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Estimated IELTS Band: $band',
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tip,
                    style: const TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 40),

            // Right side: progress + skills
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Progress bar
                  Text(
                    'Progress',
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 30,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Skills
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: skillAnalysis.entries.map((entry) {
                      Color skillColor;
                      if (entry.value.contains("Excellent") ||
                          entry.value.contains("Strong") ||
                          entry.value.contains("Good")) {
                        skillColor = Colors.greenAccent;
                      } else if (entry.value.contains("Average")) {
                        skillColor = Colors.tealAccent;
                      } else {
                        skillColor = Colors.redAccent;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          "${entry.key}: ${entry.value}",
                          style: TextStyle(color: skillColor, fontSize: 20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gradeColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // EndScreen → QuizScreen
                      Navigator.pop(context); // QuizScreen → CardLevelScreen
                    },
                    child: const Text(
                      'Back to Levels',
                      style: TextStyle(fontSize: 22, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
