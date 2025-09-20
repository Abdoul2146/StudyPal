import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import 'topicsPage.dart';

class SubjectsPage extends ConsumerWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    // final searchProvider = StateProvider<String>((ref) => '');

    return userAsync.when(
      data: (user) {
        // keep stored format normalized for your DB documents
        final gradeLevel = (user?.gradeLevel ?? '').replaceAll(' ', '');
        // print('gradeLevel: $gradeLevel');

        return Scaffold(
          appBar: AppBar(
            title: const Text("Subjects"),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: SubjectSearchDelegate(ref),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('curriculums') // <-- changed
                    .doc(gradeLevel) // gradeLevel should be 'SS1', 'SS2', etc.
                    .collection('subjects')
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final subjects = snapshot.data!.docs;
              if (subjects.isEmpty) {
                return const Center(child: Text('No subjects available yet.'));
              }
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
                    final doc = subjects[index];
                    final subjectData =
                        (doc.data() as Map<String, dynamic>?) ?? {};
                    // Use doc.id as the canonical subjectId (fallback when field is missing)
                    final subjectId = doc.id;
                    // Display label prefers 'subject' field, fall back to doc.id
                    final subjectLabel =
                        (subjectData['subject'] as String?)
                                    ?.trim()
                                    .isNotEmpty ==
                                true
                            ? (subjectData['subject'] as String).trim()
                            : subjectId;
                    final imagePath =
                        subjectId.isNotEmpty
                            ? 'assets/images/${subjectId.toLowerCase().replaceAll(' ', '_')}.png'
                            : null;

                    return GestureDetector(
                      onTap: () {
                        // pass subjectId (doc id) to TopicsPage so Firestore lookup succeeds
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TopicsPage(
                                  grade: gradeLevel,
                                  subject: subjectId,
                                ),
                          ),
                        );
                      },
                      child: SubjectCard(
                        imagePath: imagePath,
                        label: subjectLabel,
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
  final String? imagePath;
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
              child:
                  imagePath != null
                      ? Image.asset(
                        imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // avoid crashing when asset missing; show placeholder
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                      : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
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

class SubjectSearchDelegate extends SearchDelegate {
  final WidgetRef ref;
  SubjectSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search subjects';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSubjectResults(context);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _buildSubjectResults(context);

  Widget _buildSubjectResults(BuildContext context) {
    final user = ref.read(userProvider).value;
    final gradeLevel = (user?.gradeLevel ?? '').replaceAll(' ', '');

    return StreamBuilder<QuerySnapshot>(
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
        final filtered =
            subjects.where((doc) {
              final subjectData = (doc.data() as Map<String, dynamic>?) ?? {};
              final subjectId = doc.id;
              final subjectLabel =
                  (subjectData['subject'] as String?)?.trim().isNotEmpty == true
                      ? (subjectData['subject'] as String).trim()
                      : subjectId;
              return subjectLabel.toLowerCase().contains(query.toLowerCase());
            }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No subjects found.'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final subjectData = (doc.data() as Map<String, dynamic>?) ?? {};
            final subjectId = doc.id;
            final subjectLabel =
                (subjectData['subject'] as String?)?.trim().isNotEmpty == true
                    ? (subjectData['subject'] as String).trim()
                    : subjectId;
            final imagePath =
                subjectId.isNotEmpty
                    ? 'assets/images/${subjectId.toLowerCase().replaceAll(' ', '_')}.png'
                    : null;

            return ListTile(
              leading:
                  imagePath != null
                      ? Image.asset(
                        imagePath,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.menu_book_rounded),
                      )
                      : const Icon(Icons.menu_book_rounded),
              title: Text(subjectLabel),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            TopicsPage(grade: gradeLevel, subject: subjectId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
