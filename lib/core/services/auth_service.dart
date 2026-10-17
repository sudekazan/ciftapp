import 'dart:async';

abstract class IAuthService {
  Future<String?> getCurrentUserId();
  Future<bool> signInWithEmail(String email, String password);
  Future<bool> signUpWithEmail(String email, String password, String name);
  Future<void> signOut();
}

/// MockAuthService allows offline & rapid simulator testing without waiting for Firebase setup
class MockAuthService implements IAuthService {
  String? _userId = 'user_demo_123';

  @override
  Future<String?> getCurrentUserId() async => _userId;

  @override
  Future<bool> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _userId = 'user_${email.hashCode}';
    return true;
  }

  @override
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _userId = 'user_${email.hashCode}';
    return true;
  }

  @override
  Future<void> signOut() async {
    _userId = null;
  }
}
