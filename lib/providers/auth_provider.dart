import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/users_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// StreamProvider that listens to Firebase Auth state and fetches user profile
final userProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userStream();
});
