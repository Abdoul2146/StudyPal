import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'completeProfile.dart';
import 'package:agent36/widgets/main_nav.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _selectedGrade;
  final List<String> gradeLevels = [
    'JSS 1',
    'JSS 2',
    'JSS 3',
    'SSS 1',
    'SSS 2',
    'SSS 3',
  ];

  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Create your account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Full Name',
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                validator:
                    (v) =>
                        v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                validator:
                    (v) =>
                        v == null || v.length < 6 ? 'Password too short' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  hintText: 'Select Grade/Class',
                ),
                value: _selectedGrade,
                items:
                    gradeLevels
                        .map(
                          (grade) => DropdownMenuItem(
                            value: grade,
                            child: Text(grade),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedGrade = v),
                validator: (v) => v == null ? 'Select grade/class' : null,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed:
                    _loading
                        ? null
                        : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          try {
                            // ref.read(userProvider.notifier).state = user;
                            if (context.mounted) {
                              Navigator.pop(context); // or push to home
                            }
                          } catch (e) {
                            setState(() => _error = e.toString());
                          }
                          setState(() => _loading = false);
                        },
                child:
                    _loading
                        ? const CircularProgressIndicator()
                        : const Text('Sign Up'),
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
                              setState(
                                () => _error = 'Google sign-in cancelled',
                              );
                            } else {
                              // ref.read(userProvider.notifier).state = user;
                              if (context.mounted) {
                                // If gradeLevel is empty, prompt user to complete profile
                                if (user.gradeLevel.isEmpty) {
                                  if (user.gradeLevel.isEmpty) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CompleteProfilePage(
                                              uid: user.uid,
                                            ),
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
                                  setState(
                                    () =>
                                        _error =
                                            'Please complete your profile by selecting your grade level.',
                                  );
                                } else {
                                  Navigator.pop(context); // or push to home
                                }
                              }
                            }
                          } catch (e) {
                            setState(() => _error = e.toString());
                          }
                          setState(() => _loading = false);
                        },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3B9FF4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B9FF4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
