import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import 'package:agent36/screens/Login_screen/login.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const List<String> _gradeLevels = [
    // 'JSS 1',
    // 'JSS 2',
    // 'JSS 3',
    'SS 1',
    'SS 2',
    'SS 3',
  ];

  Future<void> _updateUserDoc(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(data);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // Stream user progress as Map<subject, progressDouble(0..1)>
  Stream<Map<String, double>> _userProgressStream(String uid) {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
    return userDocRef.snapshots().asyncMap((docSnap) async {
      final Map<String, double> progress = {};
      final subColl = await userDocRef.collection('progress').get();
      if (subColl.docs.isNotEmpty) {
        for (var d in subColl.docs) {
          final data = d.data();
          final mastery = data['mastery'];
          double val = 0;
          if (mastery is num) {
            val = mastery.toDouble();
          } else if (mastery is String) {
            val = double.tryParse(mastery) ?? 0;
          }
          if (val > 1) val = val / 100.0;
          progress[d.id] = val.clamp(0.0, 1.0);
        }
      }
      return progress;
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Profile'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _signOut(context),
                tooltip: 'Sign out',
              ),
            ],
          ),
          body: StreamBuilder<Map<String, double>>(
            stream: _userProgressStream(user.uid),
            builder: (context, snapshot) {
              final progMap = snapshot.data ?? {};

              int overallMastery = 0;
              if ((user as dynamic).mastery is int) {
                overallMastery = (user as dynamic).mastery as int;
              }
              if (overallMastery == 0) {
                if (progMap.isNotEmpty) {
                  final avg =
                      progMap.values.fold<double>(0.0, (a, b) => a + b) /
                      progMap.length;
                  overallMastery = (avg * 100).toInt();
                }
              }
              final coins = (user as dynamic).coins ?? 0;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) {
                                    final avatars = [
                                      'assets/images/avatar.png',
                                      'assets/images/achieve0.png',
                                      'assets/images/achive1_1.png',
                                    ];
                                    return AlertDialog(
                                      title: const Text('Choose avatar'),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: GridView.count(
                                          crossAxisCount: 3,
                                          shrinkWrap: true,
                                          children:
                                              avatars.map((path) {
                                                return GestureDetector(
                                                  onTap: () async {
                                                    await _updateUserDoc(
                                                      context,
                                                      user.uid,
                                                      {'avatar': path},
                                                    );
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.asset(
                                                        path,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    (user as dynamic).avatar != null
                                        ? AssetImage((user as dynamic).avatar)
                                        : const AssetImage(
                                          'assets/images/avatar.png',
                                        ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.name.isNotEmpty ? user.name : 'Student',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.gradeLevel,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Summary row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Progress',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                SubjectProgressBar(
                                  subject: 'Mastery',
                                  progress: (overallMastery / 100.0).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              Text(
                                '$overallMastery%',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge!.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Coins',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$coins',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Per-subject progress
                      Text(
                        'Subjects',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (progMap.isEmpty)
                        const Center(child: Text('No progress recorded yet.'))
                      else
                        Column(
                          children:
                              progMap.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: SubjectProgressBar(
                                    subject: entry.key,
                                    progress: entry.value,
                                  ),
                                );
                              }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // // Recent performance area + account actions
                      // Text(
                      //   'Recent Performance',
                      //   style: Theme.of(context).textTheme.titleLarge,
                      // ),
                      // const SizedBox(height: 12),
                      // const PerformanceCard(
                      //   topic: 'Algebra Quiz',
                      //   score: '8/10',
                      //   date: '2 days ago',
                      // ),
                      // const SizedBox(height: 12),
                      // const PerformanceCard(
                      //   topic: 'Biology Test',
                      //   score: '75%',
                      //   date: '4 days ago',
                      // ),
                      const SizedBox(height: 24),

                      // Account actions
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _ProfileListTile(
                        label: 'Change Name',
                        onTap: () {
                          final ctrl = TextEditingController(text: user.name);
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text('Change name'),
                                  content: TextField(
                                    controller: ctrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Full name',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await _updateUserDoc(
                                          context,
                                          user.uid,
                                          {'name': ctrl.text.trim()},
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                      _ProfileListTile(
                        label: 'Change Grade Level',
                        onTap: () {
                          String? selected = user.gradeLevel;
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text('Select grade'),
                                  content: StatefulBuilder(
                                    builder:
                                        (c, s) =>
                                            DropdownButtonFormField<String>(
                                              value: selected,
                                              items:
                                                  _gradeLevels
                                                      .map(
                                                        (g) => DropdownMenuItem(
                                                          value: g,
                                                          child: Text(g),
                                                        ),
                                                      )
                                                      .toList(),
                                              onChanged:
                                                  (v) => s(() => selected = v),
                                            ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (selected != null) {
                                          await _updateUserDoc(
                                            context,
                                            user.uid,
                                            {'gradeLevel': selected},
                                          );
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                      _ProfileListTile(
                        label: 'Change Password (reset email)',
                        onTap: () {
                          _sendPasswordReset(context, user.email);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
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

// Reusable widgets

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
