import 'package:la_pocha/features/auth/data/datasources/auth_firebase_datasource.dart';
import 'package:la_pocha/features/auth/data/datasources/user_firestore_datasource.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._authDatasource,
    required this._userDatasource,
  });

  final AuthFirebaseDatasource _authDatasource;
  final UserFirestoreDatasource _userDatasource;

  @override
  Stream<UserProfile?> get authStateChanges {
    return _authDatasource.authStateChanges().asyncMap(_resolveProfile);
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _authDatasource.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const UnknownAuthFailure();
      }

      final profile = await _userDatasource.upsertProfile(
        uid: uid,
        displayName: displayName,
        email: email,
        isCreate: true,
      );
      return profile.toEntity();
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authDatasource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const UnknownAuthFailure();
      }

      final existing = await _userDatasource.getProfile(user.uid);
      final profile = existing == null
          ? await _userDatasource.upsertProfile(
              uid: user.uid,
              displayName: user.displayName ?? email.split('@').first,
              email: email,
              isCreate: true,
            )
          : await _userDatasource.touchProfile(uid: user.uid, email: email);

      return profile.toEntity();
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> signOut() => _authDatasource.signOut();

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _authDatasource.sendPasswordResetEmail(email);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = _authDatasource.currentUser;
    if (user == null) {
      return null;
    }
    return _resolveProfile(user);
  }

  @override
  Future<UserProfile> updateDisplayName(String displayName) async {
    try {
      final user = _authDatasource.currentUser;
      if (user == null) {
        throw const UnknownAuthFailure('No hay sesión activa.');
      }

      await _authDatasource.updateDisplayName(displayName);
      final profile = await _userDatasource.updateDisplayName(
        uid: user.uid,
        displayName: displayName,
      );
      return profile.toEntity();
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  Future<UserProfile?> _resolveProfile(dynamic user) async {
    if (user == null) {
      return null;
    }

    final uid = user.uid as String;
    final email = user.email as String? ?? '';
    final profile = await _userDatasource.getProfile(uid);
    if (profile != null) {
      return profile.toEntity();
    }

    if (email.isEmpty) {
      return null;
    }

    final created = await _userDatasource.upsertProfile(
      uid: uid,
      displayName: user.displayName as String? ?? email.split('@').first,
      email: email,
      isCreate: true,
    );
    return created.toEntity();
  }
}
