import 'package:agent36/screens/Profile_screen/completeProfile.dart';
import 'package:agent36/screens/Login_screen/forgot_password.dart';
import 'package:agent36/widgets/adminNavBar.dart';
import 'package:agent36/widgets/main_nav.dart';
import 'package:agent36/screens/Login_screen/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';

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
  static const String adminEmail = 'admin@studypal.com';
  static const String adminPassword = 'admin123';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _authErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'We couldn\'t find an account with that email. Please check or sign up.';
        case 'wrong-password':
          return 'Incorrect password. Please try again or reset your password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support for help.';
        case 'too-many-requests':
          return 'Too many login attempts. Please wait a bit and try again.';
        default:
          return e.message ?? 'Oops! Something went wrong. Please try again.';
      }
    }
    return 'Oops! ${e.toString()}';
  }

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
              // Optionally add input validation here
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
              // Optionally add input validation here
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
                          // Hardcoded admin credentials check
                          if (_emailCtrl.text.trim() == adminEmail &&
                              _passCtrl.text == adminPassword) {
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminNav(),
                                ),
                              );
                            }
                            return;
                          }

                          // Authenticate using AuthService -> will throw on invalid creds
                          final user = await ref
                              .read(authServiceProvider)
                              .login(
                                email: _emailCtrl.text.trim(),
                                password: _passCtrl.text,
                              );

                          if (user == null) {
                            setState(() => _error = 'Invalid credentials');
                          } else {
                            if (context.mounted) {
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
                          setState(() => _error = _authErrorMessage(e));
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
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
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
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
                            if (context.mounted) {
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
                          // show friendly message for google/auth errors
                          setState(() => _error = _authErrorMessage(e));
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
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
