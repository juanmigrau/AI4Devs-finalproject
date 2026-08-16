import 'package:la_pocha/features/game_setup/domain/entities/user_search_result.dart';

abstract class UserSearchRepository {
  /// Searches registered users by display name prefix (case-insensitive).
  Future<List<UserSearchResult>> searchUsers(
    String query, {
    String? excludeUid,
  });
}
