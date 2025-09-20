import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'topicContentPage.dart';

// Change TopicsPage to ConsumerWidget
class TopicsPage extends ConsumerWidget {
  final String grade;
  final String subject;
  const TopicsPage({super.key, required this.grade, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }
        final uid = user.uid;

        return StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('progress')
                  .doc(subject)
                  .snapshots(),
          builder: (context, progressSnap) {
            return Scaffold(
              appBar: AppBar(title: Text('$subject Topics')),
              body: FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('curriculums') // <-- changed
                        .doc(grade)
                        .collection('subjects')
                        .doc(subject)
                        .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final subjectDoc = snapshot.data!;
                  final topics =
                      ((subjectDoc.data()
                                  as Map<String, dynamic>?)?['topics'] ??
                              [])
                          as List<dynamic>;

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: topics.length,
                    itemBuilder: (context, idx) {
                      final topic = topics[idx] as Map<String, dynamic>;
                      final title = topic['title'] ?? 'Untitled Topic';
                      final subtopics =
                          topic['subtopics'] as List<dynamic>? ?? [];

                      return GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) {
                              // Get completed subtopics for this topic from progress
                              final completedSubtopics =
                                  (progressSnap.data?.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >?)?['completedSubtopics']
                                      as List? ??
                                  [];

                              return SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Choose a Subtopic',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 16),
                                      ...List.generate(subtopics.length, (
                                        subIdx,
                                      ) {
                                        final subtopic = subtopics[subIdx];
                                        final isDone = completedSubtopics
                                            .contains(subtopic);

                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          elevation: 2,
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.book,
                                              color:
                                                  isDone
                                                      ? Colors.green
                                                      : Colors.blue,
                                            ),
                                            title: Text(
                                              subtopic,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            trailing:
                                                isDone
                                                    ? const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    )
                                                    : null,
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => TopicContentPage(
                                                        grade: grade,
                                                        subject: subject,
                                                        topic: title,
                                                        subtopic: subtopic,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.blue[100],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.menu_book,
                                  size: 32,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtopics.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Subtopics: ${subtopics.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
