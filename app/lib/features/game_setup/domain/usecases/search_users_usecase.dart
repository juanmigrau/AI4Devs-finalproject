import 'package:la_pocha/features/game_setup/domain/entities/user_search_result.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/user_search_repository.dart';

class SearchUsersUseCase {
  SearchUsersUseCase(this._repository);

  final UserSearchRepository _repository;

  static const int minQueryLength = 2;

  /// Returns matching users. Queries shorter than [minQueryLength] skip the
  /// repository and return an empty list.
  Future<List<UserSearchResult>> call(
    String query, {
    String? excludeUid,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) {
      return const [];
    }
    return _repository.searchUsers(trimmed, excludeUid: excludeUid);
  }
}
