import 'package:flutter/material.dart';
import 'package:agent36/screens/Profile_screen/profilepage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'Login_screen/login.dart';
// import '../providers/theme_provider.dart'; // Add this import

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final themeMode = ref.watch(themeModeProvider);
    // final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            children: [
              // Account Section
              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: const AssetImage(
                          'assets/images/avatar.png',
                        ),
                        backgroundColor: Colors.white38,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'View profile',
                              style: TextStyle(color: Color(0xFF3B9FF4)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black54,
                          size: 18,
                        ),
                        onPressed: () {
                          // Navigate to profile page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Appearance Section
              // Card(
              //   color: Theme.of(context).cardColor,
              //   elevation: 1,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              //   child: ListTile(
              //     leading: const Icon(
              //       Icons.dark_mode,
              //       color: Color(0xFF3B9FF4),
              //     ),
              //     title: Text(
              //       'Dark Mode',
              //       style: Theme.of(context).textTheme.titleLarge,
              //     ),
              //     trailing: Switch(
              //       value: isDark,
              //       onChanged: (bool value) {
              //         ref.read(themeModeProvider.notifier).state =
              //             value ? ThemeMode.dark : ThemeMode.light;
              //       },
              //       activeColor: const Color(0xFF3B9FF4),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),

              // Notifications Section
              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // ListTile(
                    //   leading: const Icon(
                    //     Icons.notifications_active,
                    //     color: Color(0xFF3B9FF4),
                    //   ),
                    //   title: Text(
                    //     'Push Notifications',
                    //     style: Theme.of(context).textTheme.titleLarge,
                    //   ),
                    //   trailing: Switch(
                    //     value: true,
                    //     onChanged: (bool value) {
                    //       // Handle push notifications toggle
                    //     },
                    //     activeColor: const Color(0xFF3B9FF4),
                    //   ),
                    // ),
                    // const Divider(height: 0),
                    // ListTile(
                    //   leading: const Icon(
                    //     Icons.email,
                    //     color: Color(0xFF3B9FF4),
                    //   ),
                    //   title: Text(
                    //     'Email Notifications',
                    //     style: Theme.of(context).textTheme.titleLarge,
                    //   ),
                    //   trailing: Switch(
                    //     value: false,
                    //     onChanged: (bool value) {
                    //       // Handle email notifications toggle
                    //     },
                    //     activeColor: const Color(0xFF3B9FF4),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Support Section
              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // ListTile(
                    // leading: const Icon(
                    //     Icons.help_outline,
                    //     color: Color(0xFF3B9FF4),
                    //   ),
                    //   title: Text(
                    //     'Help Center',
                    //     style: Theme.of(context).textTheme.titleLarge,
                    //   ),
                    //   trailing: const Icon(
                    //     Icons.arrow_forward_ios,
                    //     size: 16,
                    //     color: Colors.black54,
                    //   ),
                    //   onTap: () {
                    //     // Navigate to help center
                    //   },
                    // ),
                    // const Divider(height: 0),
                    // ListTile(
                    //   leading: const Icon(
                    //     Icons.privacy_tip_outlined,
                    //     color: Color(0xFF3B9FF4),
                    //   ),
                    //   title: Text(
                    //     'Privacy Policy',
                    //     style: Theme.of(context).textTheme.titleLarge,
                    //   ),
                    //   trailing: const Icon(
                    //     Icons.arrow_forward_ios,
                    //     size: 16,
                    //     color: Colors.black54,
                    //   ),
                    //   onTap: () {
                    //     // Navigate to privacy policy
                    //   },
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B9FF4),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
