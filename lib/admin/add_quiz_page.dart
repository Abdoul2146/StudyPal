// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddQuizPage extends StatefulWidget {
  final String grade;
  final String subject;
  final String topic;
  final String? quizId;
  final Map<String, dynamic>? initialData;
  const AddQuizPage({
    super.key,
    required this.grade,
    required this.subject,
    required this.topic,
    this.quizId,
    this.initialData,
  });

  @override
  State<AddQuizPage> createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {
  final titleCtrl = TextEditingController();
  final timeLimitCtrl = TextEditingController(); // <-- Add this
  final List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      titleCtrl.text = widget.initialData!['title'] ?? '';
      timeLimitCtrl.text =
          (widget.initialData!['timeLimitMinutes'] ?? '')
              .toString(); // <-- Add this
      questions.addAll(
        List<Map<String, dynamic>>.from(widget.initialData!['questions'] ?? []),
      );
    }
  }

  void _addQuestionDialog() {
    String type = 'mcq';
    final questionCtrl = TextEditingController();
    final List<TextEditingController> optionCtrls = List.generate(
      4,
      (_) => TextEditingController(),
    );
    int correctIndex = 0;
    final answerCtrl = TextEditingController();
    bool tfAnswer = true;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Add Question'),
            content: StatefulBuilder(
              builder:
                  (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: type,
                        items: [
                          DropdownMenuItem(
                            value: 'mcq',
                            child: Text('Multiple Choice'),
                          ),
                          DropdownMenuItem(
                            value: 'tf',
                            child: Text('True/False'),
                          ),
                          DropdownMenuItem(
                            value: 'short',
                            child: Text('Short Answer'),
                          ),
                        ],
                        onChanged: (val) => setState(() => type = val ?? 'mcq'),
                        decoration: const InputDecoration(
                          labelText: 'Question Type',
                        ),
                      ),
                      TextField(
                        controller: questionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                        ),
                      ),
                      if (type == 'mcq')
                        ...List.generate(
                          4,
                          (i) => Row(
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: correctIndex,
                                onChanged:
                                    (val) =>
                                        setState(() => correctIndex = val ?? 0),
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
                      if (type == 'tf')
                        Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: tfAnswer,
                              onChanged:
                                  (val) =>
                                      setState(() => tfAnswer = val ?? true),
                            ),
                            const Text('True'),
                            Radio<bool>(
                              value: false,
                              groupValue: tfAnswer,
                              onChanged:
                                  (val) =>
                                      setState(() => tfAnswer = val ?? false),
                            ),
                            const Text('False'),
                          ],
                        ),
                      if (type == 'short')
                        TextField(
                          controller: answerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Correct Answer',
                          ),
                        ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (type == 'mcq') {
                    final options =
                        optionCtrls.map((c) => c.text.trim()).toList();
                    if (questionCtrl.text.trim().isNotEmpty &&
                        options.every((o) => o.isNotEmpty)) {
                      questions.add({
                        'type': 'mcq',
                        'question': questionCtrl.text.trim(),
                        'options': options,
                        'correctIndex': correctIndex,
                      });
                    }
                  } else if (type == 'tf') {
                    if (questionCtrl.text.trim().isNotEmpty) {
                      questions.add({
                        'type': 'tf',
                        'question': questionCtrl.text.trim(),
                        'answer': tfAnswer,
                      });
                    }
                  } else if (type == 'short') {
                    if (questionCtrl.text.trim().isNotEmpty &&
                        answerCtrl.text.trim().isNotEmpty) {
                      questions.add({
                        'type': 'short',
                        'question': questionCtrl.text.trim(),
                        'answer': answerCtrl.text.trim(),
                      });
                    }
                  }
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveQuiz() async {
    final quizData = {
      'title': titleCtrl.text.trim(),
      'grade': widget.grade,
      'subject': widget.subject,
      'topic': widget.topic,
      'questions': questions,
      'createdAt': FieldValue.serverTimestamp(),
      'timeLimitMinutes':
          int.tryParse(timeLimitCtrl.text.trim()) ?? 0, // <-- Add this
    };
    final quizRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.grade)
        .collection(widget.subject)
        .doc(widget.topic)
        .collection('quizList');
    if (widget.quizId != null) {
      await quizRef.doc(widget.quizId).set(quizData, SetOptions(merge: true));
    } else {
      await quizRef.add(quizData);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    timeLimitCtrl.dispose(); // <-- Add this
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Quiz Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeLimitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Time Limit (minutes, 0 = no limit)',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              onPressed: _addQuestionDialog,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ...questions.map(
                    (q) => Card(
                      child: ListTile(
                        title: Text(q['question']),
                        subtitle: Text(q['type']),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _saveQuiz,
              child: const Text('Save Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
