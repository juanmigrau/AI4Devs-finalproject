import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart';

/// Web OAuth client ID from `google-services.json` (client_type 3).
/// Required on Android so Google Sign-In returns a non-null `idToken`.
const String kGoogleSignInServerClientId =
    '969753324327-gb200bg1vqv5vskiddp2t2qm17s5ak0i.apps.googleusercontent.com';

class AuthFirebaseDatasource {
  AuthFirebaseDatasource(
    this._auth, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: kGoogleSignInServerClientId,
            );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _wrapAuthCall(
      () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _wrapAuthCall(
      () => _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  /// Returns `null` when the user cancels the Google account picker.
  Future<UserCredential?> signInWithGoogle() {
    return _wrapAuthCall(() async {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return _auth.signInWithCredential(credential);
    });
  }

  Future<void> signOut() {
    return _wrapAuthCall(() async {
      await Future.wait<void>([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _wrapPasswordResetCall(
      () => _auth.sendPasswordResetEmail(email: email),
    );
  }

  Future<void> updateDisplayName(String displayName) {
    return _wrapAuthCall(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw const UnknownAuthFailure('No hay sesión activa.');
      }
      await user.updateDisplayName(displayName);
      await user.reload();
    });
  }

  Future<T> _wrapAuthCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<T> _wrapPasswordResetCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw _mapPasswordResetException(error);
    }
  }

  AuthFailure _mapAuthException(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => const EmailAlreadyInUseFailure(),
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' =>
        const InvalidCredentialsFailure(),
      'network-request-failed' => const NetworkUnavailableFailure(),
      'too-many-requests' => const UnknownAuthFailure(
          'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
        ),
      'user-disabled' => const UnknownAuthFailure(
          'Esta cuenta está deshabilitada.',
        ),
      'weak-password' => const ValidationFailure(
          'La contraseña es demasiado débil. Elige una más segura.',
        ),
      'operation-not-allowed' => const UnknownAuthFailure(
          'Esta forma de acceso no está disponible ahora mismo.',
        ),
      _ => const UnknownAuthFailure(),
    };
  }

  AuthFailure _mapPasswordResetException(FirebaseAuthException error) {
    return switch (error.code) {
      'user-not-found' => const UserNotFoundFailure(),
      'invalid-email' =>
        const ValidationFailure('Introduce un email válido'),
      'network-request-failed' => const NetworkUnavailableFailure(),
      'too-many-requests' => const UnknownAuthFailure(
          'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
        ),
      'user-disabled' => const UnknownAuthFailure(
          'Esta cuenta está deshabilitada.',
        ),
      _ => const UnknownAuthFailure(),
    };
  }
}
