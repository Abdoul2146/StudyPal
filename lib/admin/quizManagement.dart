// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agent36/admin/add_quiz_page.dart';

class QuizManagementPage extends StatefulWidget {
  const QuizManagementPage({super.key});

  @override
  State<QuizManagementPage> createState() => _QuizManagementPageState();
}

class _QuizManagementPageState extends State<QuizManagementPage> {
  String searchQuery = '';

  // add controller to capture time limit (minutes)
  final TextEditingController _timeLimitCtrl = TextEditingController();

  void _editQuiz(QueryDocumentSnapshot quizDoc) {
    final data = quizDoc.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddQuizPage(
              grade: data['grade'],
              subject: data['subject'],
              topic: data['topic'],
              quizId: quizDoc.id,
              initialData: data,
            ),
      ),
    ).then((_) => setState(() {}));
  }

  void showEditQuizDialog(DocumentSnapshot quizDoc) {
    final data = quizDoc.data() as Map<String, dynamic>;
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    String type = data['type'] ?? 'Multiple Choice';
    final gradeCtrl = TextEditingController(text: data['grade'] ?? '');
    final subjectCtrl = TextEditingController(text: data['subject'] ?? '');
    final topicCtrl = TextEditingController(text: data['topic'] ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Quiz'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Quiz Title'),
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    items:
                        ['Multiple Choice', 'Short Answer', 'True/False']
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                    onChanged: (val) => type = val ?? 'Multiple Choice',
                    decoration: const InputDecoration(labelText: 'Quiz Type'),
                  ),
                  TextField(
                    controller: gradeCtrl,
                    decoration: const InputDecoration(labelText: 'Grade'),
                  ),
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  TextField(
                    controller: topicCtrl,
                    decoration: const InputDecoration(labelText: 'Topic'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await quizDoc.reference.update({
                    'title': titleCtrl.text.trim(),
                    'type': type,
                    'grade': gradeCtrl.text.trim(),
                    'subject': subjectCtrl.text.trim(),
                    'topic': topicCtrl.text.trim(),
                  });
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () async {
                  await quizDoc.reference.delete();
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

  void showQuestionsDialog(DocumentSnapshot quizDoc) {
    final data = quizDoc.data() as Map<String, dynamic>;
    List questions = data['questions'] ?? [];
    String quizType = data['type'] ?? 'Multiple Choice';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quiz Questions'),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...questions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value as Map<String, dynamic>;
                    return ListTile(
                      title: Text(q['question'] ?? ''),
                      subtitle:
                          quizType == 'Multiple Choice'
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...List.generate(
                                    (q['options'] as List).length,
                                    (i) => Row(
                                      children: [
                                        Icon(
                                          i == q['correctIndex']
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color:
                                              i == q['correctIndex']
                                                  ? Colors.green
                                                  : Colors.grey,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(q['options'][i]),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                              : quizType == 'Short Answer'
                              ? Text('Answer: ${q['answer'] ?? ''}')
                              : quizType == 'True/False'
                              ? Text(
                                'Correct Answer: ${q['answer'] == true ? "True" : "False"}',
                              )
                              : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showEditQuestionDialog(
                                quizDoc,
                                questions,
                                idx,
                                q,
                                quizType,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              questions.removeAt(idx);
                              await quizDoc.reference.update({
                                'questions': questions,
                              });
                              Navigator.pop(context);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  AddQuestionWidget(
                    quizType: quizType,
                    onAdd: (questionMap) async {
                      questions.add(questionMap);
                      await quizDoc.reference.update({'questions': questions});
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void showEditQuestionDialog(
    DocumentSnapshot quizDoc,
    List questions,
    int idx,
    Map<String, dynamic> q,
    String quizType,
  ) {
    final questionCtrl = TextEditingController(text: q['question'] ?? '');
    final List<TextEditingController> optionCtrls =
        quizType == 'Multiple Choice'
            ? List.generate(
              4,
              (i) =>
                  TextEditingController(text: (q['options'] as List)[i] ?? ''),
            )
            : [];
    int correctIndex = q['correctIndex'] ?? 0;
    final answerCtrl = TextEditingController(
      text: q['answer']?.toString() ?? '',
    );
    bool tfAnswer = q['answer'] == true;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Question'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionCtrl,
                  decoration: const InputDecoration(labelText: 'Question'),
                ),
                if (quizType == 'Multiple Choice')
                  ...List.generate(
                    4,
                    (i) => Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: correctIndex,
                          onChanged: (val) {
                            setState(() {
                              correctIndex = val ?? 0;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: optionCtrls[i],
                            decoration: InputDecoration(
                              labelText: 'Option ${i + 1}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (quizType == 'Short Answer')
                  TextField(
                    controller: answerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Correct Answer',
                    ),
                  ),
                if (quizType == 'True/False')
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: tfAnswer,
                        onChanged: (val) {
                          setState(() {
                            tfAnswer = val ?? true;
                          });
                        },
                      ),
                      const Text('True'),
                      Radio<bool>(
                        value: false,
                        groupValue: tfAnswer,
                        onChanged: (val) {
                          setState(() {
                            tfAnswer = val ?? false;
                          });
                        },
                      ),
                      const Text('False'),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final question = questionCtrl.text.trim();
                  if (quizType == 'Multiple Choice') {
                    final options =
                        optionCtrls
                            .map((c) => c.text.trim())
                            .where((o) => o.isNotEmpty)
                            .toList();
                    if (question.isNotEmpty && options.length == 4) {
                      questions[idx] = {
                        'id': q['id'],
                        'type': 'mcq',
                        'question': question,
                        'options': options,
                        'correctIndex': correctIndex,
                      };
                    }
                  } else if (quizType == 'Short Answer') {
                    if (question.isNotEmpty &&
                        answerCtrl.text.trim().isNotEmpty) {
                      questions[idx] = {
                        'id': q['id'],
                        'type': 'short',
                        'question': question,
                        'answer': answerCtrl.text.trim(),
                      };
                    }
                  } else if (quizType == 'True/False') {
                    questions[idx] = {
                      'id': q['id'],
                      'type': 'tf',
                      'question': question,
                      'answer': tfAnswer,
                    };
                  }
                  await quizDoc.reference.update({'questions': questions});
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _showQuizPickerDialog() async {
    String? selectedGrade;
    String? selectedSubject;
    String? selectedTopic;

    List<String> grades = [];
    List<String> subjects = [];
    List<String> topics = [];

    // Fetch grades from Firestore
    final gradeSnap =
        await FirebaseFirestore.instance.collection('curriculum').get();
    grades = gradeSnap.docs.map((doc) => doc.id).toList();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Select Grade, Subject & Topic'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedGrade,
                      items:
                          grades
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                      onChanged: (val) async {
                        selectedGrade = val;
                        selectedSubject = null;
                        selectedTopic = null;
                        subjects.clear();
                        topics.clear();
                        // Fetch subjects for selected grade
                        final subjectSnap =
                            await FirebaseFirestore.instance
                                .collection('curriculum')
                                .doc(selectedGrade!)
                                .collection('subjects')
                                .get();
                        setState(() {
                          subjects =
                              subjectSnap.docs.map((doc) => doc.id).toList();
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Grade'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      items:
                          subjects
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (val) async {
                        selectedSubject = val;
                        selectedTopic = null;
                        topics.clear();
                        // Fetch topics for selected subject
                        final topicSnap =
                            await FirebaseFirestore.instance
                                .collection('curriculum')
                                .doc(selectedGrade!)
                                .collection('subjects')
                                .doc(selectedSubject!)
                                .get();
                        final data = topicSnap.data();
                        setState(() {
                          topics =
                              (data?['topics'] as List<dynamic>? ?? [])
                                  .map((e) => e.toString())
                                  .toList();
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Subject'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedTopic,
                      items:
                          topics
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => selectedTopic = val),
                      decoration: const InputDecoration(labelText: 'Topic'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedGrade != null &&
                                selectedSubject != null &&
                                selectedTopic != null
                            ? () {
                              Navigator.of(ctx).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AddQuizPage(
                                        grade: selectedGrade!,
                                        subject: selectedSubject!,
                                        topic: selectedTopic!,
                                      ),
                                ),
                              );
                            }
                            : null,
                    child: const Text('Continue'),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  void dispose() {
    // ...existing dispose code...
    _timeLimitCtrl.dispose();
    // ...existing dispose code...
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quizzes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Quizzes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search quizzes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _fetchAllQuizzes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final quizzes = snapshot.data!;
                  if (quizzes.isEmpty) {
                    return const Center(child: Text('No quizzes found.'));
                  }
                  return ListView(
                    children:
                        quizzes.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['title'] ?? ''),
                            subtitle: Text(
                              '${data['grade']} • ${data['subject']} • ${data['topic']}',
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editQuiz(doc),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    // Add delete functionality
                                    await doc.reference.delete();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Quiz',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: _showQuizPickerDialog,
      ),
    );
  }

  // Helper to open edit dialog from list tile or wherever you show quizzes

  Future<List<QueryDocumentSnapshot>> _fetchAllQuizzes() async {
    try {
      // This will fetch all documents from every 'quizList' subcollection in Firestore
      final querySnap =
          await FirebaseFirestore.instance.collectionGroup('quizList').get();
      return querySnap.docs;
    } catch (e) {
      print('Error fetching quizzes: $e');
      return [];
    }
  }
}

class AddQuestionWidget extends StatefulWidget {
  final String quizType;
  final Future<void> Function(Map<String, dynamic>) onAdd;
  const AddQuestionWidget({
    super.key,
    required this.quizType,
    required this.onAdd,
  });

  @override
  State<AddQuestionWidget> createState() => _AddQuestionWidgetState();
}

class _AddQuestionWidgetState extends State<AddQuestionWidget> {
  final questionCtrl = TextEditingController();
  final List<TextEditingController> optionCtrls = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int correctIndex = 0;
  final answerCtrl = TextEditingController();
  bool tfAnswer = true;
  bool allowMultipleCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Add New Question',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: questionCtrl,
          decoration: const InputDecoration(labelText: 'Question'),
        ),
        const SizedBox(height: 8),
        if (widget.quizType == 'Multiple Choice')
          ...List.generate(
            4,
            (i) => Row(
              children: [
                Radio<int>(
                  value: i,
                  groupValue: correctIndex,
                  onChanged: (val) {
                    setState(() {
                      correctIndex = val ?? 0;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: optionCtrls[i],
                    decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                  ),
                ),
              ],
            ),
          ),
        if (widget.quizType == 'Short Answer')
          TextField(
            controller: answerCtrl,
            decoration: const InputDecoration(labelText: 'Correct Answer'),
          ),
        if (widget.quizType == 'True/False')
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: tfAnswer,
                onChanged: (val) {
                  setState(() {
                    tfAnswer = val ?? true;
                  });
                },
              ),
              const Text('True'),
              Radio<bool>(
                value: false,
                groupValue: tfAnswer,
                onChanged: (val) {
                  setState(() {
                    tfAnswer = val ?? false;
                  });
                },
              ),
              const Text('False'),
            ],
          ),
        if (widget.quizType == 'Multiple Choice')
          Column(
            children: [
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Allow Multiple Correct Answers'),
                value: allowMultipleCorrect,
                onChanged: (val) {
                  setState(() {
                    allowMultipleCorrect = val;
                  });
                },
              ),
            ],
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            final question = questionCtrl.text.trim();
            if (widget.quizType == 'Multiple Choice') {
              final options =
                  optionCtrls
                      .map((c) => c.text.trim())
                      .where((o) => o.isNotEmpty)
                      .toList();
              if (question.isNotEmpty && options.length == 4) {
                final id = DateTime.now().microsecondsSinceEpoch.toString();
                if (!allowMultipleCorrect) {
                  widget.onAdd({
                    'id': id,
                    'type': 'mcq',
                    'question': question,
                    'options': options,
                    'correctIndex': correctIndex,
                  });
                } else {
                  final selected = <int>[];
                  for (var i = 0; i < options.length; i++) {
                    if (optionCtrls[i].text.trim().isNotEmpty) {
                      selected.add(i);
                    }
                  }
                  if (selected.isNotEmpty) {
                    widget.onAdd({
                      'id': id,
                      'type': 'mcq',
                      'question': question,
                      'options': options,
                      'correctIndexes': selected,
                    });
                  }
                }
              }
            } else if (widget.quizType == 'Short Answer') {
              if (question.isNotEmpty && answerCtrl.text.trim().isNotEmpty) {
                final id = DateTime.now().microsecondsSinceEpoch.toString();
                widget.onAdd({
                  'id': id,
                  'type': 'short',
                  'question': question,
                  'answer': answerCtrl.text.trim(),
                });
              }
            } else if (widget.quizType == 'True/False') {
              final id = DateTime.now().microsecondsSinceEpoch.toString();
              widget.onAdd({
                'id': id,
                'type': 'tf',
                'question': question,
                'answer': tfAnswer,
              });
            }
          },
          child: const Text('Add Question'),
        ),
      ],
    );
  }
}
