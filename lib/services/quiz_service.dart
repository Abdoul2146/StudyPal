import 'package:cloud_firestore/cloud_firestore.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // convenience: fetch quiz by id
  Future<DocumentSnapshot> fetchQuiz(String quizId) =>
      _db.collection('quizzes').doc(quizId).get();

  // create a simple attempt (if you still need)
  Future<DocumentReference> createAttempt({
    required Map<String, dynamic> data,
  }) {
    return _db.collection('quizAttempts').add(data);
  }

  // Submit attempt and award coins/achievements in a client-side transaction.
  // WARNING: client-side awarding requires appropriate Firestore rules / AppCheck.
  Future<DocumentReference> submitAttemptAndAward({
    required String quizId,
    required String userId,
    required List<Map<String, dynamic>> answers,
    required double finalScorePercent, // 0..100
    required double maxScore,
    int coinRuleDivisor = 10, // 1 coin per 10%
  }) async {
    final attemptsColl = _db.collection('quizAttempts');
    final userRef = _db.collection('users').doc(userId);

    // 1) create attempt doc (non-transactional)
    DocumentReference attemptRef;
    try {
      attemptRef = await attemptsColl.add({
        'quizId': quizId,
        'userId': userId,
        'answers': answers,
        'finalScore': finalScorePercent,
        'maxScore': maxScore,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('submitAttemptAndAward: failed creating attempt doc: $e');
      rethrow;
    }

    // 2) read user, compute and update (non-transactional)
    try {
      final userSnap = await userRef.get();
      final userData =
          userSnap.exists
              ? (userSnap.data() as Map<String, dynamic>)
              : <String, dynamic>{};

      int currentCoins = 0;
      final rawCoins = userData['coins'];
      if (rawCoins is int) {
        currentCoins = rawCoins;
      } else if (rawCoins is String)
        currentCoins = int.tryParse(rawCoins) ?? 0;
      else if (rawCoins is double)
        currentCoins = rawCoins.toInt();

      // --- Only award coins if quiz not already completed or score improved ---
      final progressColl = userRef.collection('progress');
      bool alreadyCompleted = false;
      double? previousScore;
      // Try to find the quiz in any subject's completedQuizzes and get previous score
      final progressDocs = await progressColl.get();
      for (var doc in progressDocs.docs) {
        final data = doc.data();
        final completed = (data['completedQuizzes'] as List?) ?? [];
        if (completed.contains(quizId)) {
          alreadyCompleted = true;
          // Try to get previous score
          if (data['quizScores'] is Map) {
            final quizScores = Map<String, dynamic>.from(data['quizScores']);
            if (quizScores[quizId] != null) {
              final prev = quizScores[quizId];
              if (prev is num)
                previousScore = prev.toDouble();
              else if (prev is String)
                previousScore = double.tryParse(prev) ?? 0;
            }
          }
          break;
        }
      }

      int coinsToAdd = 0;
      final newScoreFraction = finalScorePercent / 100.0;
      final newCoinsForThisScore =
          (finalScorePercent / coinRuleDivisor).round();

      if (!alreadyCompleted) {
        coinsToAdd = newCoinsForThisScore;
      } else if (previousScore != null && newScoreFraction > previousScore) {
        // Only award the difference in coins for the improved score
        final prevCoins = (previousScore * 100 / coinRuleDivisor).round();
        coinsToAdd = newCoinsForThisScore - prevCoins;
        if (coinsToAdd < 0) coinsToAdd = 0;
      }
      final newCoins = currentCoins + coinsToAdd;

      final currentAchievements = List<Map<String, dynamic>>.from(
        (userData['achievements'] as List<dynamic>?)?.map(
              (e) =>
                  e is Map
                      ? Map<String, dynamic>.from(e)
                      : {'id': e.toString(), 'name': e.toString()},
            ) ??
            [],
      );

      final badgeId = 'quiz_pass_$quizId';
      final already = currentAchievements.any((a) => a['id'] == badgeId);
      if (finalScorePercent >= 50 && !already) {
        currentAchievements.add({
          'id': badgeId,
          'name': 'Passed quiz',
          'quizId': quizId,
          'awardedAt': Timestamp.now(),
        });
      }

      await userRef.set({
        'coins': newCoins,
        'achievements': currentAchievements,
      }, SetOptions(merge: true));
    } catch (e) {
      // mark attempt so admins can inspect; return attempt reference and rethrow
      print('submitAttemptAndAward: failed updating user (non-tx): $e');
      try {
        await attemptRef.set({
          'status': 'error',
          'error': e.toString(),
          'awarded': false,
        }, SetOptions(merge: true));
      } catch (_) {}
      rethrow;
    }

    return attemptsColl.doc(attemptRef.id);
  }

  /// Fetch attempts for a given quiz. The Firestore rules will limit what the
  /// client can read (owner or user's own attempts).
  Future<List<Map<String, dynamic>>> fetchAttemptsForQuiz(String quizId) async {
    final q =
        await _db
            .collection('quizAttempts')
            .where('quizId', isEqualTo: quizId)
            .orderBy('createdAt', descending: true)
            .get();
    return q.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).toList();
  }
}
