import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateQuizProgress({
  required String uid,
  required String subject,
  required String quizId,
  required double score, // 0.0 to 1.0
}) async {
  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc(subject);

  await docRef.set({
    'completedQuizzes': FieldValue.arrayUnion([quizId]),
    'quizScores.$quizId': score,
  }, SetOptions(merge: true));
}

Future<void> updateSubjectMastery({
  required String uid,
  required String subject,
  required int totalLessons,
  required int totalQuizzes,
}) async {
  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc(subject);

  final snap = await docRef.get();
  final data = snap.data() ?? {};
  final completedLessons = (data['completedLessons'] as List?)?.length ?? 0;
  final completedQuizzes = (data['completedQuizzes'] as List?)?.length ?? 0;

  final mastery =
      (totalLessons + totalQuizzes) == 0
          ? 0.0
          : (completedLessons + completedQuizzes) /
              (totalLessons + totalQuizzes);

  await docRef.set({'mastery': mastery}, SetOptions(merge: true));

  // --- Update overall mastery in user doc ---
  final progressColl = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('progress');
  final allProgress = await progressColl.get();
  double sum = 0;
  int count = 0;
  for (var doc in allProgress.docs) {
    final m = doc.data()['mastery'];
    double val = 0;
    if (m is num)
      val = m.toDouble();
    else if (m is String)
      val = double.tryParse(m) ?? 0;
    if (val > 1) val = val / 100.0;
    sum += val;
    count++;
  }
  final overall = count == 0 ? 0.0 : sum / count;
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'mastery': (overall * 100).toInt(),
  }, SetOptions(merge: true));
}

Future<int> getTotalLessonsForSubject(String grade, String subject) async {
  final snap =
      await FirebaseFirestore.instance
          .collection('curriculum')
          .doc(grade)
          .collection('subjects')
          .doc(subject)
          .get();
  final data = snap.data() ?? {};
  final lessons = data['lessons'] as Map<String, dynamic>? ?? {};
  return lessons.length;
}

Future<int> getTotalQuizzesForSubject(String grade, String subject) async {
  final topicsSnap =
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(grade)
          .collection(subject)
          .get();
  int total = 0;
  for (var doc in topicsSnap.docs) {
    final quizListSnap =
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(grade)
            .collection(subject)
            .doc(doc.id)
            .collection('quizList')
            .get();
    total += quizListSnap.docs.length;
  }
  return total;
}
