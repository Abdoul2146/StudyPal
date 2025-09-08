import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 80, // Adjust height as needed
            title: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                user != null
                    ? 'Hello, ${user.name} (${user.gradeLevel})!'
                    : 'Hello!',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {
                  // Handle notification tap
                },
              ),
              const SizedBox(width: 16),
            ],
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
                    'Ongoing',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200, // Height for the horizontal scrollable cards
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        // Algebra Card
                        OngoingCourseCard(
                          imagePath: 'assets/images/mathematics.jpg',
                          title: 'Mathematics',
                          subtitle: 'Lesson 3',
                        ),
                        SizedBox(width: 16),
                        // Biology Card
                        OngoingCourseCard(
                          imagePath: 'assets/images/Biology.jpeg',
                          title: 'Biology Quiz',
                          subtitle: 'Quiz 2',
                        ),
                        SizedBox(width: 16),
                        OngoingCourseCard(
                          imagePath: 'assets/images/chemistry.png',
                          title: 'Chemistry',
                          subtitle: 'In Progress',
                        ),
                        SizedBox(width: 16),
                        OngoingCourseCard(
                          imagePath: 'assets/images/physics.png',
                          title: 'Physics',
                          subtitle: 'In Progress',
                        ),
                        SizedBox(width: 16),
                        // You can add more cards here
                      ],
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
                  const ProgressItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'Overall Mastery',
                    value: '75%',
                    showProgressBar: true,
                    progressValue: 0.5,
                  ),
                  const SizedBox(height: 16),
                  // Coin Balance
                  const ProgressItem(
                    icon: Icons.money, // or Icons.toll for coins
                    label: 'Coin Balance',
                    value: '1250',
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
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle AI Tutor button tap
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
                  const SizedBox(height: 24), // Space before bottom nav bar
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
    return Container(
      width: 180, // Fixed width for the cards
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
            child: Image.asset(
              imagePath,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
