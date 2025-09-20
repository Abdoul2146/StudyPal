import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_tutor_service.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '../../utils/progress_utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TopicContentPage extends ConsumerStatefulWidget {
  final String grade;
  final String subject;
  final String topic;
  final String? subtopic;

  const TopicContentPage({
    super.key,
    required this.grade,
    required this.subject,
    required this.topic,
    this.subtopic,
  });

  @override
  ConsumerState<TopicContentPage> createState() => _TopicContentPageState();
}

class _TopicContentPageState extends ConsumerState<TopicContentPage> {
  String? _lessonMarkdown;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _quizQuestions = [];
  Map<int, dynamic> _userAnswers = {};
  bool _quizSubmitted = false;
  double _score = 0.0;
  bool _alreadyCompleted = false;
  List<String> _correctAnswers = [];
  List<Map<String, String>> _youtubeVideos = [];

  final AiTutorService _aiTutor = AiTutorService(
    '',
  );
  final String _youtubeApiKey =
      ''; // <-- Insert your YouTube API key

  @override
  void initState() {
    super.initState();
    _checkProgressAndLoad();
  }

  Future<void> _checkProgressAndLoad() async {
    final user = ref.read(userProvider).value;
    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(widget.subject);

      final subtopicKey = widget.subtopic ?? '';
      final topicKey = widget.topic;

      final doc = await docRef.get();
      final completedSubtopics =
          (doc.data()?['completedSubtopics'] as List?) ?? [];
      final quizScores = (doc.data()?['quizScores'] as Map?) ?? {};

      final scoreKey =
          '${topicKey}${subtopicKey.isNotEmpty ? '_$subtopicKey' : ''}';
      final score = quizScores[scoreKey];
      if (completedSubtopics.contains(subtopicKey) &&
          score != null &&
          score >= 0.7) {
        setState(() {
          _alreadyCompleted = true;
          _score = score;
          _quizSubmitted = true;
        });
      }
    }
    await _loadLesson();
  }

  Future<void> _loadLesson() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = ref.read(userProvider).value;
      final gradeLevel = user?.gradeLevel.replaceAll(' ', '') ?? widget.grade;
      final subtopicText = widget.subtopic ?? '';

      // 1. Fetch YouTube videos for context
      _youtubeVideos = await fetchYoutubeVideos(
        '${widget.topic} $subtopicText',
        _youtubeApiKey,
      );

      String videoContext = '';
      if (_youtubeVideos.isNotEmpty) {
        videoContext = 'I searched YouTube and found these videos:\n';
        for (var v in _youtubeVideos) {
          videoContext += '- ${v['title']} (${v['channel']}): ${v['url']}\n';
        }
      }

      // 2. Build prompt for Gemini
      final prompt = '''
$videoContext

You are a Nigerian secondary school teacher.
At the top, provide a section called "## Class Info" with:
- Topic: ${widget.topic}
- Subtopic: $subtopicText
- Class: $gradeLevel
- Date: (today's date)
- Duration: (suggested duration for the lesson, e.g. "40 minutes")

Then, teach the subtopic: "$subtopicText" under the topic "${widget.topic}" for a $gradeLevel student.
Provide a detailed lesson with:
- Simple explanations and real-life examples
- 2 worked examples
- A 3-question MCQ quiz (do NOT include answers in the quiz section)
- At the end, add a section called "## Answers" listing the correct option letter for each question (e.g. 1. c, 2. b, 3. a)
- Suggest further reading for more information at the end if possible give links/urls.

Format your response as Markdown with these sections:
## Class Info
## Explanation
## Examples
## Quiz
## Answers
## References

Ensure the content is clear, concise, and engaging.
''';

      final markdown = await _aiTutor.ask([
        {'role': 'user', 'text': prompt},
      ]);

      if (mounted) {
        setState(() {
          _lessonMarkdown = markdown;
          _quizQuestions = _parseQuiz(markdown);
          _correctAnswers = _parseAnswers(markdown);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load lesson: ${e.toString()}';
          _loading = false;
        });
        print('Error in _loadLesson: $e');
      }
    }
  }

  List<Map<String, dynamic>> _parseQuiz(String markdown) {
    final quizSection = RegExp(r'## Quiz([\s\S]*?)(##|$)').firstMatch(markdown);
    if (quizSection == null) return [];
    final quizText = quizSection.group(1)!;
    final lines =
        quizText.split('\n').where((l) => l.trim().isNotEmpty).toList();

    List<Map<String, dynamic>> questions = [];
    String? qText;
    List<String> options = [];
    for (var line in lines) {
      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        if (qText != null && options.isNotEmpty) {
          questions.add({
            'question': qText,
            'options': List<String>.from(options),
          });
        }
        qText = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        options = [];
      } else if (RegExp(r'^[a-dA-D]\)').hasMatch(line.trim())) {
        options.add(line.trim().replaceFirst(RegExp(r'^[a-dA-D]\)\s*'), ''));
      } else if (RegExp(r'([a-dA-D]\))').hasMatch(line)) {
        // Handles options in a single line: "A) Option1 B) Option2 ..."
        final optMatches = RegExp(
          r'([a-dA-D]\))\s*([^\n]+?)(?=\s*[a-dA-D]\)|$)',
        ).allMatches(line);
        for (var m in optMatches) {
          options.add(m.group(2)!.trim());
        }
      }
    }
    if (qText != null && options.isNotEmpty) {
      questions.add({'question': qText, 'options': List<String>.from(options)});
    }
    return questions;
  }

  List<String> _parseAnswers(String markdown) {
    final answersSection = RegExp(
      r'## Answers([\s\S]*?)(##|$)',
    ).firstMatch(markdown);
    List<String> correctAnswers = [];
    if (answersSection != null) {
      final lines = answersSection.group(1)!.split('\n');
      for (var line in lines) {
        final match = RegExp(r'^\d+\.\s*([a-dA-D])').firstMatch(line.trim());
        if (match != null) correctAnswers.add(match.group(1)!.toLowerCase());
      }
    }
    return correctAnswers;
  }

  Future<void> _submitQuiz() async {
    int correct = 0;
    for (int i = 0; i < _quizQuestions.length; i++) {
      final userAns = _userAnswers[i]?.toString().toLowerCase();
      if (i < _correctAnswers.length && userAns == _correctAnswers[i]) {
        correct++;
      }
    }
    setState(() {
      _score = _quizQuestions.isEmpty ? 0 : correct / _quizQuestions.length;
      _quizSubmitted = true;
    });

    // Store progress in Firestore
    final user = ref.read(userProvider).value;
    if (user != null && _score >= 0.7) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(widget.subject);

      final topicKey = widget.topic;
      final subtopicKey = widget.subtopic ?? '';

      // --- Fetch canonical subject label from curriculum ---
      final gradeLevel = widget.grade;
      final subjectId = widget.subject;
      final curriculumDoc =
          await FirebaseFirestore.instance
              .collection('curriculums')
              .doc(gradeLevel)
              .collection('subjects')
              .doc(subjectId)
              .get();
      final subjectLabel =
          (curriculumDoc.data()?['subject'] as String?)?.trim() ?? subjectId;

      // --- Save progress with canonical subject label ---
      await docRef.set({
        'subject': subjectLabel,
        'completedTopics': FieldValue.arrayUnion([topicKey]),
        if (subtopicKey.isNotEmpty)
          'completedSubtopics': FieldValue.arrayUnion([subtopicKey]),
        'quizScores.${topicKey}${subtopicKey.isNotEmpty ? '_$subtopicKey' : ''}':
            _score,
      }, SetOptions(merge: true));

      // --- Update mastery ---
      final totalLessons = await getTotalLessonsForSubject(
        widget.grade,
        widget.subject,
      );
      final totalQuizzes = await getTotalQuizzesForSubject(
        widget.grade,
        widget.subject,
      );
      await updateSubjectMastery(
        uid: user.uid,
        subject: widget.subject,
        totalLessons: totalLessons,
        totalQuizzes: totalQuizzes,
      );

      setState(() {
        _alreadyCompleted = true;
      });
    }
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.blue[50],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Icon(Icons.book, color: Colors.blue[700], size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.topic,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (widget.subtopic != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        widget.subtopic!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  if (_alreadyCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Chip(
                        label: const Text(
                          'Completed',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                        avatar: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Color? color,
  }) {
    return Card(
      color: color ?? Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  // Helper to extract YouTube video IDs from URLs
  List<String> _extractYoutubeIds(String references) {
    final matches =
        RegExp(r'https:\/\/www\.youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)')
            .allMatches(references)
            .map((m) => m.group(1))
            .whereType<String>()
            .toSet() // <-- ensures uniqueness
            .toList();
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    }

    // Split markdown into sections for cards
    String explanation = '';
    String examples = '';
    final expMatch = RegExp(
      r'## Explanation([\s\S]*?)(##|$)',
    ).firstMatch(_lessonMarkdown ?? '');
    final exMatch = RegExp(
      r'## Examples([\s\S]*?)(##|$)',
    ).firstMatch(_lessonMarkdown ?? '');
    final quizMatch = RegExp(
      r'## Quiz([\s\S]*?)(##|$)',
    ).firstMatch(_lessonMarkdown ?? '');
    final refMatch = RegExp(
      r'## References([\s\S]*?)(##|$)',
    ).firstMatch(_lessonMarkdown ?? '');
    String references = '';
    if (refMatch != null) references = refMatch.group(1)!.trim();

    final classInfoMatch = RegExp(
      r'## Class Info([\s\S]*?)(##|$)',
    ).firstMatch(_lessonMarkdown ?? '');
    String classInfo = '';
    if (classInfoMatch != null) classInfo = classInfoMatch.group(1)!.trim();

    // Insert current date and bold "Date:"
    final today = DateTime.now();
    final formattedDate = "${today.day}/${today.month}/${today.year}";
    if (classInfo.isNotEmpty) {
      classInfo = classInfo.replaceAllMapped(
        RegExp(r'Date:.*'),
        (match) => 'Date:** $formattedDate',
      );
    }

    if (expMatch != null) explanation = expMatch.group(1)!.trim();
    if (exMatch != null) examples = exMatch.group(1)!.trim();
    if (quizMatch != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.subtopic != null
                ? '${widget.topic} - ${widget.subtopic}'
                : widget.topic,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (classInfo.isNotEmpty)
                _buildSectionCard(
                  title: 'Lesson Info',
                  color: Colors.grey[100],
                  child: MarkdownBody(
                    data: classInfo,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    extensionSet: md.ExtensionSet(
                      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                      <md.InlineSyntax>[
                        md.EmojiSyntax(),
                        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                      ],
                    ),
                  ),
                ),
              _buildHeaderCard(),
              if (explanation.isNotEmpty)
                _buildSectionCard(
                  title: 'Explanation',
                  color: Colors.yellow[50],
                  child: MarkdownBody(
                    data: explanation,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    extensionSet: md.ExtensionSet(
                      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                      <md.InlineSyntax>[
                        md.EmojiSyntax(),
                        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                      ],
                    ),
                  ),
                ),
              if (examples.isNotEmpty)
                _buildSectionCard(
                  title: 'Examples',
                  color: Colors.green[50],
                  child: MarkdownBody(
                    data: examples,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    extensionSet: md.ExtensionSet(
                      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                      <md.InlineSyntax>[
                        md.EmojiSyntax(),
                        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                      ],
                    ),
                  ),
                ),
              if (_quizQuestions.isNotEmpty)
                _buildSectionCard(
                  title: 'Quiz',
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: _userAnswers.length / _quizQuestions.length,
                        backgroundColor: Colors.blue[100],
                        color: Colors.blue[700],
                        minHeight: 6,
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_quizQuestions.length, (i) {
                        final q = _quizQuestions[i];
                        final userAns = _userAnswers[i];
                        final correctAns =
                            i < _correctAnswers.length
                                ? _correctAnswers[i]
                                : null;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. ${q['question']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(q['options'].length, (j) {
                                  final optLetter = String.fromCharCode(
                                    97 + j,
                                  ); // a, b, c, d
                                  final isSelected = userAns == optLetter;
                                  final isCorrect =
                                      _quizSubmitted && correctAns == optLetter;
                                  final isWrong =
                                      _quizSubmitted &&
                                      isSelected &&
                                      !isCorrect;
                                  return RadioListTile(
                                    value: optLetter,
                                    groupValue: userAns,
                                    onChanged:
                                        _quizSubmitted || _alreadyCompleted
                                            ? null
                                            : (val) => setState(
                                              () => _userAnswers[i] = val,
                                            ),
                                    title: Text(
                                      '${optLetter.toUpperCase()}) ${q['options'][j]}',
                                      style: TextStyle(
                                        color:
                                            isCorrect
                                                ? Colors.green
                                                : isWrong
                                                ? Colors.red
                                                : Colors.black87,
                                        fontWeight:
                                            isCorrect || isWrong
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    secondary:
                                        isCorrect
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                            : isWrong
                                            ? const Icon(
                                              Icons.cancel,
                                              color: Colors.red,
                                            )
                                            : null,
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (!_quizSubmitted && !_alreadyCompleted)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          onPressed:
                              _userAnswers.length == _quizQuestions.length
                                  ? _submitQuiz
                                  : null,
                          label: const Text('Submit Quiz'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      if (_quizSubmitted || _alreadyCompleted)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Text(
                                'Score: ${(_score * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color:
                                      _score >= 0.7
                                          ? Colors.green
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _score >= 0.7
                                    ? 'Great job! You have completed this subtopic.'
                                    : 'Let\'s try again for a better score!',
                                style: TextStyle(
                                  color:
                                      _score >= 0.7
                                          ? Colors.green
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_quizSubmitted && _score < 0.7)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {
                              _quizSubmitted = false;
                              _userAnswers.clear();
                            });
                            _loadLesson();
                          },
                          label: const Text('Repeat Lesson'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      if ((_quizSubmitted && _score >= 0.7) ||
                          _alreadyCompleted)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          label: const Text('Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              if (references.isNotEmpty)
                _buildSectionCard(
                  title: 'References & Further Learning',
                  color: Colors.purple[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: references,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        extensionSet: md.ExtensionSet(
                          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                          <md.InlineSyntax>[
                            md.EmojiSyntax(),
                            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                          ],
                        ),
                      ),
                      ..._extractYoutubeIds(references)
                          .take(2)
                          .map(
                            (videoId) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: YoutubePlayer(
                                controller: YoutubePlayerController(
                                  initialVideoId: videoId,
                                  flags: const YoutubePlayerFlags(
                                    autoPlay: false,
                                    mute: false,
                                  ),
                                ),
                                showVideoProgressIndicator: true,
                                progressIndicatorColor: Colors.red,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Default fallback if no content is found
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subtopic != null
              ? '${widget.topic} - ${widget.subtopic}'
              : widget.topic,
        ),
      ),
      body: Center(
        child: Text(
          'No lesson content available.',
          style: const TextStyle(fontSize: 18, color: Colors.red),
        ),
      ),
    );
  }
}
