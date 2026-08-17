import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserProfile> signIn({required String email, required String password});

  /// Returns `null` when the user cancels the Google account picker.
  Future<UserProfile?> signInWithGoogle();

  Future<void> signOut();

  Future<void> sendPasswordReset({required String email});

  Future<UserProfile?> getCurrentUser();

  Future<UserProfile> updateDisplayName(String displayName);

  /// Deletes the Firestore profile and the Firebase Auth user.
  ///
  /// [password] is required when email/password reauthentication is needed.
  Future<void> deleteAccount({String? password});
}
