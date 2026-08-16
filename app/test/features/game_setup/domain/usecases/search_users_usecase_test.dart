import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/user_search_result.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/user_search_repository.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/search_users_usecase.dart';

class _FakeUserSearchRepository implements UserSearchRepository {
  String? lastQuery;
  String? lastExcludeUid;
  int callCount = 0;
  List<UserSearchResult> resultsToReturn = const [];

  @override
  Future<List<UserSearchResult>> searchUsers(
    String query, {
    String? excludeUid,
  }) async {
    callCount++;
    lastQuery = query;
    lastExcludeUid = excludeUid;
    return resultsToReturn;
  }
}

void main() {
  late _FakeUserSearchRepository repository;
  late SearchUsersUseCase useCase;

  setUp(() {
    repository = _FakeUserSearchRepository();
    useCase = SearchUsersUseCase(repository);
  });

  test('empty query does not call repository', () async {
    final results = await useCase('');

    expect(results, isEmpty);
    expect(repository.callCount, 0);
  });

  test('query shorter than 2 characters does not call repository', () async {
    final results = await useCase('a');

    expect(results, isEmpty);
    expect(repository.callCount, 0);
  });

  test(
    'query with whitespace only shorter than 2 does not call repository',
    () async {
      final results = await useCase(' a ');

      expect(results, isEmpty);
      expect(repository.callCount, 0);
    },
  );

  test('query with at least 2 characters calls repository', () async {
    const expected = [
      UserSearchResult(
        uid: 'u1',
        displayName: 'Ana',
        email: 'ana@gmail.com',
      ),
    ];
    repository.resultsToReturn = expected;

    final results = await useCase('an', excludeUid: 'me');

    expect(results, expected);
    expect(repository.callCount, 1);
    expect(repository.lastQuery, 'an');
    expect(repository.lastExcludeUid, 'me');
  });

  test('trims query before calling repository', () async {
    await useCase('  ana  ');

    expect(repository.callCount, 1);
    expect(repository.lastQuery, 'ana');
    expect(repository.lastExcludeUid, isNull);
  });
}
