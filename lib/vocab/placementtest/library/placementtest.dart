class QuizQuestion {
  final int id;
  final String question;
  final List<String> choices;
  final int correctIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.choices,
    required this.correctIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      choices: List<String>.from(json['choices']),
      correctIndex: json['correctIndex'],
    );
  }
  static List<QuizQuestion> listFromJson(List<Map<String, dynamic>> list) {
    return list.map((m) => QuizQuestion.fromJson(m)).toList();
  }
}
