import 'package:la_pocha/features/auth/data/datasources/user_firestore_datasource.dart';
import 'package:la_pocha/features/game_setup/domain/entities/user_search_result.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/user_search_repository.dart';

class UserSearchRepositoryImpl implements UserSearchRepository {
  UserSearchRepositoryImpl(this._datasource);

  final UserFirestoreDatasource _datasource;

  @override
  Future<List<UserSearchResult>> searchUsers(
    String query, {
    String? excludeUid,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    final docs = await _datasource.searchUsers(normalized);
    final results = <UserSearchResult>[];

    for (final doc in docs) {
      if (excludeUid != null && doc.uid == excludeUid) {
        continue;
      }

      final searchKey = doc.searchName ?? doc.displayName.toLowerCase();
      if (!searchKey.startsWith(normalized)) {
        continue;
      }

      results.add(
        UserSearchResult(
          uid: doc.uid,
          displayName: doc.displayName,
          email: doc.email,
          photoUrl: doc.photoUrl,
        ),
      );
    }

    return results;
  }
}
