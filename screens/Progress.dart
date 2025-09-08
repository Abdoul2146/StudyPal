import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        return Scaffold(
          appBar: AppBar(title: Text("Progress"), centerTitle: true),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MARK: - Profile Section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: const AssetImage(
                            'assets/images/avatar.png',
                          ), // Placeholder user avatar
                          backgroundColor: Colors.grey[200],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.name ?? 'Student',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // MARK: - Overall Progress
                  Text(
                    'Overall Progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const SubjectProgressBar(
                    subject: 'Mathematics',
                    progress: 0.85,
                  ),
                  const SizedBox(height: 16),
                  const SubjectProgressBar(subject: 'Science', progress: 0.60),
                  const SizedBox(height: 16),
                  const SubjectProgressBar(subject: 'History', progress: 0.45),
                  const SizedBox(height: 32),

                  // MARK: - Recent Performance
                  Text(
                    'Recent Performance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const PerformanceCard(
                    topic: 'Algebra Quiz',
                    score: '8/10',
                    date: '2 days ago',
                  ),
                  const SizedBox(height: 16),
                  const PerformanceCard(
                    topic: 'Biology Test',
                    score: '75%',
                    date: '4 days ago',
                  ),
                  const SizedBox(height: 16),
                  const PerformanceCard(
                    topic: 'World War II Quiz',
                    score: '9/10',
                    date: '1 week ago',
                  ),
                ],
              ),
            ),
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

// MARK: - Reusable Widgets

// Widget for a subject progress bar
class SubjectProgressBar extends StatelessWidget {
  final String subject;
  final double progress;

  const SubjectProgressBar({
    super.key,
    required this.subject,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).hintColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${(progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for a recent performance card
class PerformanceCard extends StatelessWidget {
  final String topic;
  final String score;
  final String date;

  const PerformanceCard({
    super.key,
    required this.topic,
    required this.score,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(date, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Text(
            score,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
