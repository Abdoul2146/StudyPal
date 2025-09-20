import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agent36/screens/Login_screen/login.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  void showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final auth = FirebaseAuth.instance;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                ),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final user = auth.currentUser;
                  if (user == null) return;
                  if (newPassCtrl.text != confirmPassCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }
                  try {
                    final cred = EmailAuthProvider.credential(
                      email: user.email!,
                      password: oldPassCtrl.text,
                    );
                    await user.reauthenticateWithCredential(cred);
                    await user.updatePassword(newPassCtrl.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('Change'),
              ),
            ],
          ),
    );
  }

  void showEditProfileDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: false,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (user != null) {
                    await user.updateDisplayName(nameCtrl.text.trim());
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Optionally clear any local storage or providers here
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => showEditProfileDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              onTap: () => showChangePasswordDialog(context),
            ),
            // ListTile(
            //   leading: const Icon(Icons.notifications_outlined),
            //   title: const Text('Notifications'),
            //   onTap: () {},
            // ),
            // ListTile(
            //   leading: const Icon(Icons.info_outline),
            //   title: const Text('About'),
            //   onTap: () {},
            // ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
