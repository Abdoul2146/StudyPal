import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'topicsPage.dart';

class SubjectsPage extends ConsumerWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        final gradeLevel = (user?.gradeLevel ?? '').replaceAll(' ', '');
        print('gradeLevel: $gradeLevel');

        return Scaffold(
          appBar: AppBar(
            title: const Text("Subjects"),
            centerTitle: true,
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('curriculum')
                    .doc(gradeLevel)
                    .collection('subjects')
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final subjects = snapshot.data!.docs;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: List.generate(subjects.length, (index) {
                    final subject =
                        subjects[index].data() as Map<String, dynamic>;
                    final subjectName = subject['subject'] ?? '';
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TopicsPage(
                                  grade: gradeLevel,
                                  subject: subjectName,
                                ),
                          ),
                        );
                      },
                      child: SubjectCard(
                        imagePath:
                            'assets/images/${subjectName.toLowerCase().replaceAll(' ', '_')}.png',
                        label: subjectName,
                      ),
                    );
                  }),
                ),
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

// Custom Card for Subjects
class SubjectCard extends StatelessWidget {
  final String imagePath;
  final String label;

  const SubjectCard({super.key, required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Example function (replace with your actual data source)
List<String> getSubjectsForGrade(String gradeLevel) {
  final Map<String, List<String>> gradeSubjects = {
    'JSS 1': ['Mathematics', 'English', 'Basic Science'],
    'JSS 2': ['Mathematics', 'English', 'Social Studies'],
    'SSS 3': ['Mathematics', 'Biology', 'Chemistry'],
    // ...etc
  };
  return gradeSubjects[gradeLevel] ?? [];
}
