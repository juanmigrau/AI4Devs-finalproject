import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:la_pocha/features/auth/data/models/user_profile_model.dart';

/// Raw Firestore user document fields needed for name search.
class UserSearchDoc {
  const UserSearchDoc({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.searchName,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? searchName;
}

class UserFirestoreDatasource {
  UserFirestoreDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Prefix search on [searchName], limited to 10 results, 5s timeout.
  Future<List<UserSearchDoc>> searchUsers(String normalizedQuery) async {
    final snapshot = await _users
        .where('searchName', isGreaterThanOrEqualTo: normalizedQuery)
        .where('searchName', isLessThan: '${normalizedQuery}z')
        .orderBy('searchName')
        .limit(10)
        .get()
        .timeout(const Duration(seconds: 5));

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return UserSearchDoc(
        uid: doc.id,
        displayName: data['displayName'] as String? ?? '',
        email: data['email'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        searchName: data['searchName'] as String?,
      );
    }).toList();
  }

  Future<UserProfileModel?> getProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserProfileModel.fromFirestore(uid, snapshot.data()!);
  }

  Future<UserProfileModel> upsertProfile({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
    bool isCreate = false,
  }) async {
    final model = UserProfileModel(
      uid: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _users.doc(uid).set(
          model.toFirestore(isCreate: isCreate),
          SetOptions(merge: true),
        );

    final saved = await getProfile(uid);
    return saved ?? model;
  }

  Future<UserProfileModel> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    await _users.doc(uid).set(
      {
        'displayName': displayName,
        'searchName': displayName.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final saved = await getProfile(uid);
    if (saved == null) {
      throw StateError('User profile not found: $uid');
    }
    return saved;
  }

  Future<UserProfileModel> touchProfile({
    required String uid,
    required String email,
  }) async {
    await _users.doc(uid).set(
      {
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final saved = await getProfile(uid);
    if (saved != null) {
      return saved;
    }

    return UserProfileModel(
      uid: uid,
      displayName: email.split('@').first,
      email: email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
