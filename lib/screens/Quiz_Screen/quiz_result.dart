import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';

class QuizResultPage extends StatelessWidget {
  final Quiz quiz;
  final Map<String, dynamic> userAnswers; // questionId -> answer
  final double scorePercent;

  const QuizResultPage({
    super.key,
    required this.quiz,
    required this.userAnswers,
    required this.scorePercent,
  });

  @override
  Widget build(BuildContext context) {
    int correctCount = 0;

    List<Widget> questionResults = [];
    for (var q in quiz.questions) {
      bool isCorrect = false;
      final userAnswer = userAnswers[q.id];

      if (q.type == 'mcq') {
        if (q.correctIndexes != null && q.correctIndexes!.isNotEmpty) {
          final expect = q.correctIndexes!.toSet();
          final got =
              (userAnswer is List)
                  ? Set<int>.from(userAnswer.map((e) => e as int))
                  : (userAnswer is int ? {userAnswer} : <int>{});
          if (got.isNotEmpty &&
              got.length == expect.length &&
              got.containsAll(expect)) {
            isCorrect = true;
          }
        } else if (q.correctIndex != null) {
          if (userAnswer is int && userAnswer == q.correctIndex)
            isCorrect = true;
        }
      } else if (q.type == 'tf') {
        if (userAnswer is bool && q.answer != null) {
          final exp = (q.answer.toString().toLowerCase() == 'true');
          if (userAnswer == exp) isCorrect = true;
        }
      } else {
        final corr = (q.answer ?? '').toString().trim().toLowerCase();
        final got = (userAnswer ?? '').toString().trim().toLowerCase();
        if (corr.isNotEmpty && got.isNotEmpty && corr == got) {
          isCorrect = true;
        }
      }

      if (isCorrect) correctCount++;

      questionResults.add(
        Card(
          color: isCorrect ? Colors.green[50] : Colors.red[50],
          child: ListTile(
            title: Text(q.question),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your answer: ${_formatUserAnswer(q, userAnswer)}'),
                if (!isCorrect)
                  Text(
                    'Correct answer: ${_formatCorrectAnswer(q)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            trailing: Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Score: $correctCount / ${quiz.questions.length} (${scorePercent.toStringAsFixed(1)}%)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...questionResults,
        ],
      ),
    );
  }

  String _formatUserAnswer(Question q, dynamic answer) {
    if (q.type == 'mcq') {
      if (answer is List) {
        return answer.map((i) => q.options[i]).join(', ');
      } else if (answer is int && answer >= 0 && answer < q.options.length) {
        return q.options[answer];
      }
      return answer?.toString() ?? '';
    } else if (q.type == 'tf') {
      return (answer == true) ? 'True' : (answer == false ? 'False' : '');
    } else {
      return answer?.toString() ?? '';
    }
  }

  String _formatCorrectAnswer(Question q) {
    if (q.type == 'mcq') {
      if (q.correctIndexes != null && q.correctIndexes!.isNotEmpty) {
        return q.correctIndexes!.map((i) => q.options[i]).join(', ');
      } else if (q.correctIndex != null &&
          q.correctIndex! >= 0 &&
          q.correctIndex! < q.options.length) {
        return q.options[q.correctIndex!];
      }
      return '';
    } else if (q.type == 'tf') {
      return (q.answer?.toLowerCase() == 'true') ? 'True' : 'False';
    } else {
      return q.answer?.toString() ?? '';
    }
  }
}
