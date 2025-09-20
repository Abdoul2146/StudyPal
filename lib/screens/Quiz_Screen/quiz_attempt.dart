import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/quiz_model.dart';
import '../../widgets/question_card.dart';
import '../../widgets/quiz_navigation.dart';
import '../../services/quiz_service.dart';
import '../../providers/auth_provider.dart';
import 'quiz_result.dart';
// import '../../utils/progress_utils.dart';

class QuizAttemptPage extends ConsumerStatefulWidget {
  final String quizId;
  final String quizDocPath; // <-- add this
  const QuizAttemptPage({
    super.key,
    required this.quizId,
    required this.quizDocPath,
  });

  @override
  ConsumerState<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends ConsumerState<QuizAttemptPage> {
  final _controller = PageController();
  final Map<String, dynamic> _answers = {};
  bool _submitting = false;
  final QuizService _service = QuizService();

  int remainingSeconds = 0;
  Timer? _timer;

  bool _timeUpDialogShown = false;
  Timer? _timeUpCountdownTimer;

  late Future<Quiz> _quizFuture; // load once
  int _currentIndex = 0; // <-- add

  @override
  void initState() {
    super.initState();
    _quizFuture = _loadQuiz(); // start load only once
  }

  Future<Quiz> _loadQuiz() async {
    final snap =
        await FirebaseFirestore.instance
            .doc(widget.quizDocPath) // <-- use the full path
            .get();
    final data = snap.data() ?? {};
    final quiz = Quiz.fromMap(snap.id, data);

    // init timer if present
    if (quiz.timeLimitMinutes != null && quiz.timeLimitMinutes! > 0) {
      remainingSeconds = quiz.timeLimitMinutes! * 60;
      _startTimer(quiz);
    }
    return quiz;
  }

  void _startTimer(Quiz quiz) {
    _timer?.cancel();
    if (remainingSeconds <= 0) {
      // if already expired, show dialog immediately once
      if (!_submitting && !_timeUpDialogShown) _showTimeUpDialog(quiz);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => remainingSeconds--);
      if (remainingSeconds <= 0) {
        t.cancel();
        if (!_submitting && !_timeUpDialogShown) {
          _showTimeUpDialog(quiz);
        }
      }
    });
  }

  void _showTimeUpDialog(Quiz quiz) {
    _timeUpDialogShown = true;
    int countdown = 1; // one-second countdown
    _timeUpCountdownTimer?.cancel();

    // show dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // start countdown after dialog is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _timeUpCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
            timer,
          ) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            setState(() {
              countdown--;
            });
            if (countdown <= 0) {
              timer.cancel();
              if (Navigator.canPop(ctx)) Navigator.of(ctx).pop();
              // ensure we mark submitting and call _submit
              if (!_submitting) _submit(quiz);
              _timeUpDialogShown = false;
            }
          });
        });

        return AlertDialog(
          title: const Text("Time's up"),
          content: StatefulBuilder(
            builder: (_, setInner) {
              // small timer to update content text when countdown changes
              return SizedBox(
                height: 48,
                child: Center(child: Text('Submitting in $countdown...')),
              );
            },
          ),
        );
      },
    ).then((_) {
      // dialog closed - ensure countdown timer is cancelled
      _timeUpCountdownTimer?.cancel();
      _timeUpDialogShown = false;
    });
  }

  Future<void> _submit(Quiz quiz) async {
    final user = ref
        .read(userProvider)
        .maybeWhen(data: (u) => u, orElse: () => null);
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in')));
      }
      return;
    }
    setState(() => _submitting = true);

    final questions = quiz.questions;
    final maxScore = questions.fold<double>(0, (a, b) => a + b.points);
    final answersList =
        questions.map((q) {
          final a = _answers[q.id];
          final m = <String, dynamic>{'qId': q.id};
          if (a is int) {
            m['answerIndex'] = a;
          } else {
            m['text'] = a?.toString() ?? '';
          }
          return m;
        }).toList();

    final finalScore = _scoreFromAnswers(quiz);

    try {
      // DEBUG: print the answers we're about to submit
      print('DEBUG: answersList raw -> $answersList');

      // sanitize helper that converts non-primitive values to strings
      dynamic _sanitize(dynamic v) {
        if (v == null) return null;
        if (v is num || v is String || v is bool) return v;
        if (v is List) return v.map((e) => _sanitize(e)).toList();
        if (v is Map) {
          final out = <String, dynamic>{};
          v.forEach((k, val) {
            out[k.toString()] = _sanitize(val);
          });
          return out;
        }
        // fallback: use toString for unknown types
        return v.toString();
      }

      final sanitizedAnswers =
          answersList
              .map((m) => Map<String, dynamic>.from(_sanitize(m) as Map))
              .toList();
      print('DEBUG: answersList sanitized -> $sanitizedAnswers');

      // Quick non-transactional tests to isolate failing write
      final db = FirebaseFirestore.instance;
      try {
        final doc = await db.collection('quizAttempts').add({
          'quizId': quiz.id,
          'userId': user.uid,
          'answers': sanitizedAnswers,
          'finalScore': finalScore,
          'maxScore': maxScore,
          'status': 'debug-test',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('DEBUG: non-tx add to quizAttempts OK id=${doc.id}');
        // cleanup test doc
        await db.collection('quizAttempts').doc(doc.id).delete();
        print('DEBUG: cleaned up debug attempt doc');
      } catch (e, st) {
        print('DEBUG: quizAttempts add failed: $e');
        print(st);
        throw e; // stop; we found the failing write
      }

      // test writing to user doc (merge) to detect permission/serialization problems
      try {
        await db.collection('users').doc(user.uid).set({
          'debug_update': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('DEBUG: users/${user.uid} write OK');
        // cleanup
        await db.collection('users').doc(user.uid).update({
          'debug_update': FieldValue.delete(),
        });
        print('DEBUG: cleaned up debug user field');
      } catch (e, st) {
        print('DEBUG: users write failed: $e');
        print(st);
        throw e;
      }

      // If diagnostic writes succeeded, attempt the transaction using sanitized data
      await _service.submitAttemptAndAward(
        quizId: quiz.id,
        userId: user.uid,
        answers: sanitizedAnswers,
        finalScorePercent: finalScore,
        maxScore: maxScore,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => QuizResultPage(
                  quiz: quiz,
                  userAnswers: Map<String, dynamic>.from(_answers),
                  scorePercent: finalScore,
                ),
          ),
        );
      }
    } catch (e, st) {
      print('Submit failed (diagnostic): $e');
      print(st);
      String message = 'Submit failed: ${e.runtimeType}';
      if (e is FirebaseException) {
        message = 'Submit failed: ${e.code} ${e.message ?? ''}';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double _scoreFromAnswers(Quiz quiz) {
    double total = 0, scored = 0;
    for (var q in quiz.questions) {
      total += q.points;
      final given = _answers[q.id];
      if (q.type == 'mcq') {
        if (q.correctIndexes != null && q.correctIndexes!.isNotEmpty) {
          // multiple-correct: compare sets
          final expect = q.correctIndexes!.toSet();
          final got =
              (given is List<int>)
                  ? Set<int>.from(given)
                  : (given is int ? {given} : <int>{});
          if (got.isNotEmpty &&
              got.length == expect.length &&
              got.containsAll(expect)) {
            scored += q.points;
          }
        } else if (q.correctIndex != null) {
          if (given is int && given == q.correctIndex) scored += q.points;
        }
      } else if (q.type == 'tf') {
        if (given is bool && q.answer != null) {
          final exp = (q.answer.toString().toLowerCase() == 'true');
          if (given == exp) scored += q.points;
        }
      } else {
        // short answer
        final corr = (q.answer ?? '').toString().trim().toLowerCase();
        final got = (given ?? '').toString().trim().toLowerCase();
        if (corr.isNotEmpty && got.isNotEmpty && corr == got) {
          scored += q.points;
        }
      }
    }
    if (total == 0) return 0.0;
    return (scored / total) * 100.0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeUpCountdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // format seconds as MM:SS for the app bar timer
  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Quiz>(
      future: _quizFuture, // use stored future to avoid reloads
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: Text('Quiz not found')));
        }
        final quiz = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(quiz.title),
            actions: [
              if (quiz.timeLimitMinutes != null && quiz.timeLimitMinutes! > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      _formatTime(remainingSeconds),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: quiz.questions.length,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged:
                      (i) => setState(
                        () => _currentIndex = i,
                      ), // <-- keep index in state
                  itemBuilder: (context, idx) {
                    final q = quiz.questions[idx];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ${idx + 1} of ${quiz.questions.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            QuestionCard(
                              question: q,
                              selected: _answers[q.id],
                              onSelected:
                                  (val) => setState(() => _answers[q.id] = val),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: QuizNavigation(
                  index: _currentIndex, // <-- use stable index
                  total: quiz.questions.length,
                  onPrev:
                      _currentIndex > 0
                          ? () {
                            _controller.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          }
                          : null,
                  onNext:
                      _currentIndex < quiz.questions.length - 1
                          ? () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          }
                          : null,
                  onSubmit: _submitting ? null : () => _submit(quiz),
                ),
              ),
              if (_submitting) const LinearProgressIndicator(minHeight: 4),
            ],
          ),
        );
      },
    );
  }
}
