import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AccountProvider { apple, google }

enum LinkResult {
  linked,

  /// The Apple/Google account already belongs to another Yanyana account.
  alreadyInUse,
  cancelled,
  failed,
}

/// Turns the anonymous Firebase account into a permanent one (Apple / Google)
/// so data survives a phone change or reinstall, and signs back in on a new
/// device.
class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

  bool _googleInitialized = false;

  static String _providerId(AccountProvider p) => p == AccountProvider.apple ? 'apple.com' : 'google.com';

  /// Sign in with Apple is offered on iOS (required there whenever Google is).
  bool get isAppleAvailable => Firebase.apps.isNotEmpty && !kIsWeb && Platform.isIOS;

  /// Google needs an OAuth client in the Firebase config files; hidden until
  /// the Google provider is enabled and the files are regenerated.
  bool get isGoogleAvailable {
    if (Firebase.apps.isEmpty || kIsWeb) return false;
    final options = Firebase.app().options;
    return Platform.isIOS ? options.iosClientId != null : options.androidClientId != null;
  }

  List<AccountProvider> get availableProviders => [
        if (isAppleAvailable) AccountProvider.apple,
        if (isGoogleAvailable) AccountProvider.google,
      ];

  List<AccountProvider> get linkedProviders {
    if (Firebase.apps.isEmpty) return const [];
    final ids = FirebaseAuth.instance.currentUser?.providerData.map((p) => p.providerId).toSet() ?? {};
    return AccountProvider.values.where((p) => ids.contains(_providerId(p))).toList();
  }

  Future<AuthCredential?> _googleCredential() async {
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize(clientId: Platform.isIOS ? Firebase.app().options.iosClientId : null);
      _googleInitialized = true;
    }
    if (!google.supportsAuthenticate()) return null;
    final account = await google.authenticate();
    return GoogleAuthProvider.credential(idToken: account.authentication.idToken);
  }

  static bool _isCancel(Object e) =>
      (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) ||
      (e is FirebaseAuthException && (e.code == 'canceled' || e.code == 'web-context-canceled'));

  /// Links the current (anonymous) account; all data stays where it is.
  Future<LinkResult> link(AccountProvider provider) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return LinkResult.failed;
    try {
      if (provider == AccountProvider.apple) {
        await user.linkWithProvider(AppleAuthProvider());
      } else {
        final credential = await _googleCredential();
        if (credential == null) return LinkResult.failed;
        await user.linkWithCredential(credential);
      }
      return LinkResult.linked;
    } on FirebaseAuthException catch (e) {
      debugPrint('AccountService: link error: ${e.code}');
      if (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked') {
        return LinkResult.alreadyInUse;
      }
      return _isCancel(e) ? LinkResult.cancelled : LinkResult.failed;
    } catch (e) {
      debugPrint('AccountService: link error: $e');
      return _isCancel(e) ? LinkResult.cancelled : LinkResult.failed;
    }
  }

  /// Signs in to an existing account on this device. Returns the uid, or
  /// `null` when cancelled or failed.
  Future<String?> signIn(AccountProvider provider) async {
    try {
      final UserCredential result;
      if (provider == AccountProvider.apple) {
        result = await FirebaseAuth.instance.signInWithProvider(AppleAuthProvider());
      } else {
        final credential = await _googleCredential();
        if (credential == null) return null;
        result = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      return result.user?.uid;
    } catch (e) {
      debugPrint('AccountService: sign-in error: $e');
      return null;
    }
  }
}
