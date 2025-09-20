/// Firestore quiz document shape (recommended)
/// quizzes/{quizId} = {
///   title: string,
///   grade: string,
///   subject: string,
///   topic: string,
///   questions: [ { id: string, type: 'mcq'|'tf'|'short', question: string,
///                 options: [string], correctIndex: int, answer: string, points: int } ],
///   createdAt: timestamp
/// }
class Quiz {
  final String id;
  final String title;
  final String? grade;
  final String? subject;
  final String? topic;
  final List<Question> questions;
  final int? timeLimitMinutes; // minutes

  Quiz({
    required this.id,
    required this.title,
    this.grade,
    this.subject,
    this.topic,
    required this.questions,
    this.timeLimitMinutes,
  });

  factory Quiz.fromMap(String id, Map<String, dynamic> map) {
    final qs = <Question>[];
    final raw = map['questions'];
    if (raw is List) {
      for (var q in raw) {
        if (q is Map) {
          // normalize keys to String, dynamic
          final m = Map<String, dynamic>.from(
            q.map((k, v) => MapEntry(k.toString(), v)),
          );
          try {
            qs.add(Question.fromMap(m));
          } catch (_) {
            // skip malformed question entries
          }
        }
      }
    }

    int? parseIntField(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    return Quiz(
      id: id,
      title: (map['title'] ?? '').toString(),
      grade: map['grade']?.toString(),
      subject: map['subject']?.toString(),
      topic: map['topic']?.toString(),
      questions: qs,
      timeLimitMinutes:
          parseIntField(map['timeLimitMinutes']) ??
          parseIntField(map['timeLimit']) ??
          0,
    );
  }
}

class Question {
  final String id;
  final String type; // normalized: 'mcq' | 'tf' | 'short'
  final String question;
  final List<String> options;
  final int? correctIndex;
  final List<int>? correctIndexes;
  final String? answer;
  final int points;

  Question({
    required this.id,
    required this.type,
    required this.question,
    this.options = const [],
    this.correctIndex,
    this.correctIndexes,
    this.answer,
    this.points = 1,
  });

  // normalize common admin-provided type strings to internal tokens
  static String _normalizeType(String? raw) {
    final t = (raw ?? '').toString().trim().toLowerCase();
    if (t.contains('short') || t.contains('fill') || t.contains('answer'))
      return 'short';
    if (t.contains('true') ||
        t.contains('false') ||
        t == 'tf' ||
        t == 'truefalse')
      return 'tf';
    // assume anything with 'multi' / 'multiple' means multi-correct MCQ
    if (t.contains('multi') || t.contains('multiple')) return 'mcq';
    // default to mcq for compatibility
    return 'mcq';
  }

  factory Question.fromMap(Map<String, dynamic> m) {
    List<String> parseOptions(dynamic v) {
      if (v is List) return v.map((e) => e?.toString() ?? '').toList();
      return const [];
    }

    List<int>? parseInts(dynamic v) {
      if (v is List)
        return v.map((e) => int.tryParse(e.toString()) ?? 0).toList();
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final rawType = (m['type'] ?? m['questionType'] ?? '').toString();
    final type = _normalizeType(rawType);

    // ensure id exists
    final rawId = (m['id'] ?? m['qId'] ?? m['questionId'] ?? '').toString();
    final id =
        rawId.isNotEmpty
            ? rawId
            : DateTime.now().microsecondsSinceEpoch.toString();

    return Question(
      id: id,
      type: type,
      question: (m['question'] ?? m['prompt'] ?? '').toString(),
      options: parseOptions(m['options']),
      correctIndex: parseInt(m['correctIndex']),
      correctIndexes: parseInts(m['correctIndexes']),
      answer: m['answer']?.toString(),
      points: parseInt(m['points']) ?? 1,
    );
  }
}
