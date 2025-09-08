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
