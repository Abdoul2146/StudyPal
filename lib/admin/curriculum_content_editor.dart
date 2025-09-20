import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class CurriculumContentEditorPage extends StatefulWidget {
  final String grade;
  final String subjectId;
  final String topic;
  final dynamic lessonContent;

  const CurriculumContentEditorPage({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.topic,
    this.lessonContent,
  });

  @override
  State<CurriculumContentEditorPage> createState() =>
      _CurriculumContentEditorPageState();
}

class _CurriculumContentEditorPageState
    extends State<CurriculumContentEditorPage> {
  late quill.QuillController _mainContentController;
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _objectivesControllers = [];
  final List<TextEditingController> _questionsControllers = [];
  final List<Map<String, TextEditingController>> _subtopicsControllers = [];

  bool _loading = true;
  bool _saving = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _mainContentController = quill.QuillController.basic();
    _fetchContent();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (var ctrl in _objectivesControllers) {
      ctrl.dispose();
    }
    for (var ctrl in _questionsControllers) {
      ctrl.dispose();
    }
    for (var subtopic in _subtopicsControllers) {
      subtopic['description']?.dispose();
      subtopic['content']?.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchContent() async {
    setState(() => _loading = true);
    try {
      final docSnap =
          await FirebaseFirestore.instance
              .collection('curriculum')
              .doc(widget.grade)
              .collection('subjects')
              .doc(widget.subjectId)
              .get();

      final data = docSnap.data();
      if (data != null && data['lessons'] != null) {
        final lesson = data['lessons'][widget.topic];
        if (lesson != null) {
          // Load description
          _descriptionController.text = lesson['description'] ?? '';

          // Load learning objectives
          final objectives = List<String>.from(
            lesson['learning_objectives'] ?? [],
          );
          for (var obj in objectives) {
            final ctrl = TextEditingController(text: obj);
            _objectivesControllers.add(ctrl);
          }

          // Load example questions
          final questions = List<String>.from(
            lesson['example_questions'] ?? [],
          );
          for (var q in questions) {
            final ctrl = TextEditingController(text: q);
            _questionsControllers.add(ctrl);
          }

          // Load subtopics
          final subtopics = List<Map<String, dynamic>>.from(
            lesson['subtopics'] ?? [],
          );
          for (var sub in subtopics) {
            _subtopicsControllers.add({
              'description': TextEditingController(
                text: sub['description'] ?? '',
              ),
              'content': TextEditingController(text: sub['content'] ?? ''),
            });
          }

          // Load main content
          if (lesson['main_content'] is List) {
            try {
              _mainContentController = quill.QuillController(
                document: quill.Document.fromJson(lesson['main_content']),
                selection: const TextSelection.collapsed(offset: 0),
              );
            } catch (_) {}
          }

          // Load image URL
          _imageUrl = lesson['image_url'];
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading content: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final lessonData = {
        'description': _descriptionController.text,
        'learning_objectives':
            _objectivesControllers.map((c) => c.text).toList(),
        'example_questions': _questionsControllers.map((c) => c.text).toList(),
        'subtopics':
            _subtopicsControllers
                .map(
                  (sub) => {
                    'description': sub['description']!.text,
                    'content': sub['content']!.text,
                  },
                )
                .toList(),
        'main_content': _mainContentController.document.toDelta().toJson(),
        'image_url': _imageUrl,
        'last_updated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('curriculum')
          .doc(widget.grade)
          .collection('subjects')
          .doc(widget.subjectId)
          .set({
            'lessons': {widget.topic: lessonData},
          }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Lesson — ${widget.topic}'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save, color: Colors.black),
            label:
                _saving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter lesson description',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Learning Objectives
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Objectives',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _objectivesControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._objectivesControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Learning objective ${idx + 1}',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _objectivesControllers.removeAt(idx);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Example Questions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Example Questions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _questionsControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._questionsControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Example question ${idx + 1}',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _questionsControllers.removeAt(idx);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Main Content Editor
            Text(
              'Main Content',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  quill.QuillSimpleToolbar(controller: _mainContentController),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(8),
                    child: quill.QuillEditor.basic(
                      controller: _mainContentController,
                      config: const quill.QuillEditorConfig(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subtopics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtopics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _subtopicsControllers.add({
                        'description': TextEditingController(),
                        'content': TextEditingController(),
                      });
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._subtopicsControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final sub = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Subtopic ${idx + 1}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _subtopicsControllers.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: sub['description'],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: sub['content'],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Content',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
