import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agent36/screens/Quiz_Screen/quiz_attempt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class QuizzesPage extends ConsumerWidget {
  final String? grade;
  final String? subject;
  const QuizzesPage({super.key, this.grade, this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        final studentGrade = grade ?? (user?.gradeLevel.toString() ?? '');

        return Scaffold(
          appBar: AppBar(
            title: Text(subject != null ? '$subject Quizzes' : 'Quizzes'),
            // backgroundColor: Colors.white,
            centerTitle: true,
            // elevation: 3,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collectionGroup('quizList')
                    .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              String normalize(String s) =>
                  s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
              final normStudent =
                  (studentGrade).isNotEmpty ? normalize(studentGrade) : '';
              final filtered =
                  docs.where((doc) {
                    final q = doc.data() as Map<String, dynamic>;
                    final qGrade = (q['grade'] ?? '').toString();
                    final qSubject = (q['subject'] ?? '').toString();
                    final matchesGrade =
                        normStudent.isEmpty
                            ? true
                            : normalize(qGrade) == normStudent;
                    final matchesSubject =
                        (subject == null || subject!.isEmpty)
                            ? true
                            : normalize(qSubject) == normalize(subject!);
                    return matchesGrade && matchesSubject;
                  }).toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('No quizzes available.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final q = filtered[i].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(q['title'] ?? 'Untitled'),
                    subtitle: Text(
                      '${q['grade'] ?? ''} • ${q['subject'] ?? ''} • ${q['topic'] ?? ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QuizAttemptPage(
                                quizId: filtered[i].id,
                                quizDocPath:
                                    filtered[i].reference.path, // pass path!
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
