import 'package:cloud_firestore/cloud_firestore.dart';

class Curriculum {
  final String grade;
  final String subject;
  final List<String> topics;

  Curriculum({
    required this.grade,
    required this.subject,
    required this.topics,
  });

  factory Curriculum.fromMap(Map<String, dynamic> map) {
    return Curriculum(
      grade: map['grade'],
      subject: map['subject'],
      topics: List<String>.from(map['topics']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'grade': grade, 'subject': subject, 'topics': topics};
  }
}

class SubjectModel {
  final String id;
  final String subject;
  final List<String> topics;
  final Map<String, dynamic>
  lessons; // topic -> content (String | Delta JSON | Map)

  SubjectModel({
    required this.id,
    required this.subject,
    required this.topics,
    required this.lessons,
  });

  factory SubjectModel.fromDoc(DocumentSnapshot doc) {
    final raw = doc.data() as Map<String, dynamic>? ?? {};
    final rawTopics = raw['topics'] as List<dynamic>?;
    final topics =
        rawTopics
            ?.map((e) => e?.toString().trim())
            .where((s) => s != null && s.isNotEmpty)
            .map((s) => s!)
            .toList() ??
        <String>[];

    final lessonsMap =
        raw['lessons'] is Map
            ? Map<String, dynamic>.from(raw['lessons'] as Map)
            : <String, dynamic>{};

    return SubjectModel(
      id: doc.id,
      subject: (raw['subject'] ?? doc.id).toString(),
      topics: topics,
      lessons: lessonsMap,
    );
  }

  Map<String, dynamic> toMap() => {
    'subject': subject,
    'topics': topics,
    'lessons': lessons,
  };
}
