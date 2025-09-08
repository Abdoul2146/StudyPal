import 'package:agent36/screens/completeProfile.dart';
import 'package:agent36/screens/forgot_password.dart';
import 'package:agent36/widgets/main_nav.dart';
import 'package:agent36/screens/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFFF0F0F0),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFFF0F0F0),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF3B9FF4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed:
                  _loading
                      ? null
                      : () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        try {
                          // ref.read(userProvider.notifier).state = user;
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainNav(),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => _error = e.toString());
                        }
                        setState(() => _loading = false);
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B9FF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Or continue with',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed:
                  _loading
                      ? null
                      : () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        try {
                          final user =
                              await ref
                                  .read(authServiceProvider)
                                  .signInWithGoogle();
                          if (user == null) {
                            setState(() => _error = 'Google sign-in cancelled');
                          } else {
                            // ref.read(userProvider.notifier).state = user;
                            if (context.mounted) {
                              // If gradeLevel is empty, prompt user to complete profile
                              if (user.gradeLevel.isEmpty) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            CompleteProfilePage(uid: user.uid),
                                  ),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MainNav(),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          setState(() => _error = e.toString());
                        }
                        setState(() => _loading = false);
                      },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/google_logo.png', height: 24, width: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Color(0xFF3B9FF4),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
