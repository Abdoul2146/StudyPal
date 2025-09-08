import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                // Handle back button action
                Navigator.pop(context);
              },
            ),
            title: Text(
              user != null
                  ? 'Hello, ${user.name} (${user.gradeLevel})!'
                  : 'Hello!',
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MARK: - Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: const AssetImage(
                            'assets/images/avatar.png',
                          ),
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.name ?? 'Student',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.gradeLevel ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
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

                  // MARK: - Achievements Section
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _AchievementCard(
                          value: '12',
                          label: 'Badges',
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AchievementCard(
                          value: '5',
                          label: 'Rewards',
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _AchievementCard(
                          value: '1500',
                          label: 'Coins',
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: const [
                      _AchievementGridItem(
                        imagePath: 'assets/images/achieve0.png',
                      ),
                      _AchievementGridItem(
                        imagePath: 'assets/images/achive1_1.png',
                      ),
                      _AchievementGridItem(
                        imagePath: 'assets/images/achive3.png',
                      ),
                      _AchievementGridItem(
                        imagePath: 'assets/images/achive4.png',
                      ),
                      _AchievementGridItem(
                        imagePath: 'assets/images/achive5.png',
                      ),
                      _AchievementGridItem(
                        imagePath: 'assets/images/achive6.png',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // MARK: - Account Section
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _ProfileListTile(label: 'Change Name', onTap: () {}),
                  _ProfileListTile(label: 'Change Avatar', onTap: () {}),
                  _ProfileListTile(label: 'Change Grade Level', onTap: () {}),
                  _ProfileListTile(label: 'Change Password', onTap: () {}),
                  const SizedBox(height: 32),
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

// MARK: - Custom Reusable Widgets

class _AchievementCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _AchievementCard({
    required this.value,
    required this.label,
    required this.color,
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
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AchievementGridItem extends StatelessWidget {
  final String imagePath;

  const _AchievementGridItem({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ProfileListTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleLarge),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}
