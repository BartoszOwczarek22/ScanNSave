import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/services/auth_service.dart';
import 'package:scan_n_save/services/register_service.dart';

final isLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

final authProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final isRegisteringProvider = StateProvider<bool>((ref) {
  return false;
});

final registerProvider = Provider<RegisterService>((ref) {
  return RegisterService();
});

final emailVerificationProvider = StateProvider<bool>((ref) {
  return false;
});