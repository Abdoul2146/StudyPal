import 'package:agent36/widgets/main_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  final String uid;
  const CompleteProfilePage({super.key, required this.uid});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  String? _selectedGrade;
  bool _loading = false;
  String? _error;
  final List<String> gradeLevels = [
    // 'JSS 1',
    // 'JSS 2',
    // 'JSS 3',
    'SS 1',
    'SS 2',
    'SS 3',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Select your grade/class:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedGrade,
              items:
                  gradeLevels
                      .map(
                        (grade) =>
                            DropdownMenuItem(value: grade, child: Text(grade)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedGrade = v),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFF0F0F0),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                hintText: 'Select Grade/Class',
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed:
                  _loading || _selectedGrade == null
                      ? null
                      : () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        try {
                          // Update Firestore
                          await ref
                              .read(authServiceProvider)
                              .updateUserGradeLevel(
                                widget.uid,
                                _selectedGrade!,
                              );
                          // Refresh userProvider
                          // ref.read(userProvider.notifier).state = updatedUser;
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
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
