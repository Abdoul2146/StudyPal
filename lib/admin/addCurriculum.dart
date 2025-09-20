// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:agent36/models/curriculum_model.dart';
import 'package:agent36/admin/curriculum_content_editor.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage> {
  Future<List<String>> fetchGrades() async {
    final gradesSnap =
        await FirebaseFirestore.instance.collection('curriculum').get();
    final grades = gradesSnap.docs.map((doc) => doc.id).toList();
    return grades;
  }

  Future<List<SubjectModel>> fetchSubjects(String grade) async {
    final subjectsSnap =
        await FirebaseFirestore.instance
            .collection('curriculum')
            .doc(grade)
            .collection('subjects')
            .get();
    return subjectsSnap.docs.map((doc) => SubjectModel.fromDoc(doc)).toList();
  }

  void showAddSubjectDialog(String grade) {
    final subjectCtrl = TextEditingController();
    final topicsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                ),
                TextField(
                  controller: topicsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Topics (comma separated)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final subject = subjectCtrl.text.trim();
                  final topics =
                      topicsCtrl.text
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                  if (subject.isNotEmpty && topics.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('curriculum')
                        .doc(grade)
                        .collection('subjects')
                        .doc(subject)
                        .set({
                          'grade': grade,
                          'subject': subject,
                          'topics': topics,
                          'lessons': {},
                        });
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void showEditSubjectDialog(String grade, SubjectModel s) {
    final subjectCtrl = TextEditingController(text: s.subject);
    final topicsCtrl = TextEditingController(text: s.topics.join(', '));
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                ),
                TextField(
                  controller: topicsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Topics (comma separated)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final subject = subjectCtrl.text.trim();
                  final topics =
                      topicsCtrl.text
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                  if (subject.isNotEmpty && topics.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('curriculum')
                        .doc(grade)
                        .collection('subjects')
                        .doc(s.id)
                        .update({'subject': subject, 'topics': topics});
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('curriculum')
                      .doc(grade)
                      .collection('subjects')
                      .doc(s.id)
                      .delete();
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // smoother navigation: push and await result (don't replace)
  Future<void> showEditLessonDialog(
    String grade,
    String subjectId,
    String topic,
    dynamic lessonContent,
  ) async {
    // use builder param "_" and package import to avoid load/capture issues
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => CurriculumContentEditorPage(
              grade: grade,
              subjectId: subjectId,
              topic: topic,
              lessonContent: lessonContent,
            ),
      ),
    );
    if (saved == true) setState(() {});
  }

  void showAddGradeDialog() {
    final gradeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Grade'),
            content: TextField(
              controller: gradeCtrl,
              decoration: const InputDecoration(labelText: 'Grade Name'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final grade = gradeCtrl.text.trim();
                  if (grade.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('curriculum')
                        .doc(grade)
                        .set({});
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Curriculum',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: FutureBuilder<List<String>>(
          future: fetchGrades(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final grades = snapshot.data!;
            return ListView(
              children: [
                const Text(
                  'Grades',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 16),
                ...grades.map(
                  (grade) => ExpansionTile(
                    title: Text(
                      grade,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      FutureBuilder<List<SubjectModel>>(
                        future: fetchSubjects(grade),
                        builder: (context, subjectSnap) {
                          if (!subjectSnap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final subjects = subjectSnap.data!;
                          return Column(
                            children: [
                              ...subjects.map((subject) {
                                final topics = subject.topics;
                                final lessons = subject.lessons;
                                return ExpansionTile(
                                  title: Text(subject.subject),
                                  subtitle: Text('Topics: ${topics.length}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        () => showEditSubjectDialog(
                                          grade,
                                          subject,
                                        ),
                                  ),
                                  children: [
                                    ReorderableListView(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      onReorder: (oldIndex, newIndex) async {
                                        final updatedTopics = List<String>.from(
                                          topics,
                                        );
                                        if (newIndex > oldIndex) newIndex--;
                                        final topic = updatedTopics.removeAt(
                                          oldIndex,
                                        );
                                        updatedTopics.insert(newIndex, topic);

                                        await FirebaseFirestore.instance
                                            .collection('curriculum')
                                            .doc(grade)
                                            .collection('subjects')
                                            .doc(subject.id)
                                            .update({'topics': updatedTopics});
                                        setState(() {});
                                      },
                                      children: [
                                        for (final topic in topics)
                                          ListTile(
                                            key: ValueKey(
                                              '${subject.id}::$topic',
                                            ),
                                            title: Text(topic),
                                            subtitle:
                                                (() {
                                                  final lesson = lessons[topic];
                                                  if (lesson == null) {
                                                    return const Text(
                                                      'No lesson content',
                                                    );
                                                  }
                                                  if (lesson is Map &&
                                                      lesson['description'] !=
                                                          null &&
                                                      lesson['description']
                                                          .toString()
                                                          .isNotEmpty) {
                                                    final desc =
                                                        lesson['description']
                                                            as String;
                                                    return Text(
                                                      desc.length > 30
                                                          ? 'Lesson: ${desc.substring(0, 30)}...'
                                                          : 'Lesson: $desc',
                                                    );
                                                  }
                                                  if (lesson is Map &&
                                                      lesson['content'] !=
                                                          null &&
                                                      lesson['content']
                                                          .toString()
                                                          .isNotEmpty) {
                                                    final content =
                                                        lesson['content']
                                                            as String;
                                                    return Text(
                                                      content.length > 30
                                                          ? 'Lesson: ${content.substring(0, 30)}...'
                                                          : 'Lesson: $content',
                                                    );
                                                  }
                                                  if (lesson is List &&
                                                      lesson.isNotEmpty) {
                                                    try {
                                                      final doc = quill
                                                          .Document.fromJson(
                                                        lesson,
                                                      );
                                                      final text =
                                                          doc.toPlainText();
                                                      return Text(
                                                        text.length > 30
                                                            ? 'Lesson: ${text.substring(0, 30)}...'
                                                            : 'Lesson: $text',
                                                      );
                                                    } catch (e) {
                                                      return const Text(
                                                        'Invalid lesson content',
                                                      );
                                                    }
                                                  }
                                                  if (lesson is String &&
                                                      lesson
                                                          .trim()
                                                          .isNotEmpty) {
                                                    return Text(
                                                      lesson.length > 30
                                                          ? 'Lesson: ${lesson.substring(0, 30)}...'
                                                          : 'Lesson: $lesson',
                                                    );
                                                  }
                                                  return const Text(
                                                    'No lesson content',
                                                  );
                                                })(),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_note,
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          showEditLessonDialog(
                                                            grade,
                                                            subject.id,
                                                            topic,
                                                            lessons[topic],
                                                          ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () async {
                                                    final updatedTopics =
                                                        List<String>.from(
                                                          topics,
                                                        );
                                                    updatedTopics.remove(topic);

                                                    final updatedLessons = Map<
                                                      String,
                                                      dynamic
                                                    >.from(lessons);
                                                    updatedLessons.remove(
                                                      topic,
                                                    );

                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                          'curriculum',
                                                        )
                                                        .doc(grade)
                                                        .collection('subjects')
                                                        .doc(subject.id)
                                                        .update({
                                                          'topics':
                                                              updatedTopics,
                                                          'lessons':
                                                              updatedLessons,
                                                        });
                                                    setState(() {});
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                              ListTile(
                                leading: const Icon(Icons.add),
                                title: const Text('Add Subject'),
                                onTap: () => showAddSubjectDialog(grade),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: showAddGradeDialog,
                    child: const Text(
                      'Add Grade',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
