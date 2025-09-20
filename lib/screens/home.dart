import 'package:agent36/screens/AITutor/aiTutor.dart';
import 'package:agent36/screens/Subject_Screen/subjectsPage.dart';
import 'package:agent36/widgets/main_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import './Subject_Screen/topicsPage.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Stream<List<Map<String, dynamic>>> ongoingCoursesStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('progress')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .where((doc) {
                    final data = doc.data();
                    // Show subject if ANY subtopic or topic is completed
                    final completedSubtopics =
                        (data['completedSubtopics'] as List?) ?? [];
                    final completedTopics =
                        (data['completedTopics'] as List?) ?? [];
                    return completedSubtopics.isNotEmpty ||
                        completedTopics.isNotEmpty;
                  })
                  .map((doc) {
                    final subjectData = doc.data();
                    final subjectLabel =
                        (subjectData['subject'] as String?)?.trim() ?? doc.id;
                    return {
                      'title': doc.id, // For navigation, use doc.id
                      'label':
                          subjectLabel, // For display, use saved subject label
                      'subtitle': 'Started',
                      'imagePath':
                          'assets/images/${doc.id.toLowerCase().replaceAll(' ', '_')}.png',
                    };
                  })
                  .toList(),
        );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream(user!.uid),
          builder: (context, userSnap) {
            final userData = userSnap.data?.data();
            final coins = userData?['coins'] ?? 0;
            int mastery = 0;
            if (userData?['mastery'] is int) {
              mastery = userData?['mastery'] as int;
            }

            // If mastery is missing or zero, compute average from progress subcollection
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('progress')
                      .snapshots(),
              builder: (context, progressSnap) {
                if (progressSnap.hasData && (mastery == 0)) {
                  final docs = progressSnap.data!.docs;
                  double sum = 0;
                  int count = 0;
                  for (var doc in docs) {
                    final m = doc['mastery'];
                    double val = 0;
                    if (m is num) {
                      val = m.toDouble();
                    } else if (m is String) {
                      val = double.tryParse(m) ?? 0;
                    }
                    if (val > 1) val = val / 100.0;
                    sum += val;
                    count++;
                  }
                  if (count > 0) {
                    mastery = (sum / count * 100).toInt();
                  }
                }

                return Scaffold(
                  appBar: AppBar(
                    // backgroundColor: Theme.of(context).primaryColor,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 80, // Adjust height as needed
                    title: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        // ignore: unnecessary_null_comparison
                        user != null ? 'Hello, ${user.name}!' : 'Hello!',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    // actions: [
                    //   IconButton(
                    //     icon: const Icon(Icons.notifications_none, size: 28),
                    //     onPressed: () {
                    //       // Handle notification tap
                    //     },
                    //   ),
                    //   const SizedBox(width: 16),
                    // ],
                  ),
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // MARK: Ongoing Section
                          Text(
                            'Ongoing Subjects',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200, // Match card height
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: ongoingCoursesStream(user.uid),
                              builder: (context, snap) {
                                final ongoing = snap.data ?? [];
                                if (ongoing.isEmpty) {
                                  return const Center(
                                    child: Text('No ongoing Subjects yet.'),
                                  );
                                }
                                return ListView(
                                  scrollDirection: Axis.horizontal,
                                  children:
                                      ongoing.map((course) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => TopicsPage(
                                                      grade: user.gradeLevel
                                                          .replaceAll(' ', ''),
                                                      subject: course['title'],
                                                    ),
                                              ),
                                            );
                                          },
                                          child: OngoingCourseCard(
                                            imagePath: course['imagePath'],
                                            title:
                                                course['label'], // Display label
                                            subtitle: course['subtitle'],
                                          ),
                                        );
                                      }).toList(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          // MARK: Progress Section
                          Text(
                            'Progress',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          // Overall Mastery
                          ProgressItem(
                            icon: Icons.emoji_events_outlined,
                            label: 'Overall Mastery',
                            value: '$mastery%',
                            showProgressBar: true,
                            progressValue: (mastery / 100),
                          ),
                          const SizedBox(height: 16),
                          // Coin Balance
                          ProgressItem(
                            icon: Icons.money,
                            label: 'Coin Balance',
                            value: '$coins',
                            showProgressBar: false,
                          ),
                          const SizedBox(height: 32),

                          // MARK: Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle Subjects button tap
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const SubjectsPage(),
                                      ),
                                    );
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const MainNav(initialIndex: 1),
                                      ),
                                    );
                                  },
                                  style: Theme.of(
                                    context,
                                  ).elevatedButtonTheme.style!.copyWith(
                                    backgroundColor: MaterialStateProperty.all(
                                      Theme.of(context).primaryColor,
                                    ),
                                    padding: MaterialStateProperty.all(
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                  child: Text(
                                    'Subjects',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle AI Tutor button tap
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const AiTutorPage(),
                                      ),
                                    );
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const MainNav(initialIndex: 2),
                                      ),
                                    );
                                  },
                                  style: Theme.of(
                                    context,
                                  ).elevatedButtonTheme.style!.copyWith(
                                    backgroundColor: MaterialStateProperty.all(
                                      Theme.of(context).hintColor,
                                    ), // Using hintColor for AI Tutor button
                                    padding: MaterialStateProperty.all(
                                      const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                  child: Text(
                                    'AI Tutor',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge!.copyWith(
                                      color: Colors.black87,
                                    ), // Adjust text color for AI Tutor button
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 24,
                          ), // Space before bottom nav bar
                        ],
                      ),
                    ),
                  ),
                );
              },
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

// MARK: - Custom Widgets for Reusability

class OngoingCourseCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const OngoingCourseCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      imagePath,
      height: 120, // Increased back to 120
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) => Container(
            height: 120,
            color: Colors.grey[200],
            child: const Icon(Icons.book, size: 48, color: Colors.grey),
          ),
    );

    return Container(
      width: 180,
      height: 200, // Increased card height
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
      ), // Add horizontal spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: imageWidget,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0), // More padding for text
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showProgressBar;
  final double progressValue; // 0.0 to 1.0

  const ProgressItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showProgressBar = false,
    this.progressValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).hintColor, // Light grey background for icon
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                ),
                if (showProgressBar) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Theme.of(context).hintColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
