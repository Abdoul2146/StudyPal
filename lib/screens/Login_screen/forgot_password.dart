import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reset your password',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const Text(
              'Enter your email address and we\'ll send you instructions to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: Color(0xFFF0F0F0),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_message != null)
              Text(_message!, style: const TextStyle(color: Colors.green)),
            ElevatedButton(
              onPressed:
                  _loading
                      ? null
                      : () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                          _message = null;
                        });
                        try {
                          await ref
                              .read(authServiceProvider)
                              .sendPasswordResetEmail(_emailCtrl.text.trim());
                          setState(() {
                            _message =
                                'Password reset link sent! Check your email.';
                          });
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
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
