import 'package:flutter/material.dart';

class QuizNavigation extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const QuizNavigation({
    super.key,
    required this.index,
    required this.total,
    this.onPrev,
    this.onNext,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Row(
      children: [
        ElevatedButton(
          onPressed: index > 0 ? onPrev : null,
          child: const Text('Previous'),
        ),
        const Spacer(),
        if (!isLast)
          ElevatedButton(onPressed: onNext, child: const Text('Next'))
        else
          ElevatedButton(onPressed: onSubmit, child: const Text('Submit')),
      ],
    );
  }
}
