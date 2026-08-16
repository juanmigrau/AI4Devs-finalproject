import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/utils/user_search_helper.dart';

void main() {
  group('UserSearchHelper.obfuscateEmail', () {
    test('obfuscates standard gmail address', () {
      expect(
        UserSearchHelper.obfuscateEmail('juanmigrau@gmail.com'),
        'j***@gmail.com',
      );
    });

    test('obfuscates single-letter local part', () {
      expect(UserSearchHelper.obfuscateEmail('a@b.co'), 'a***@b.co');
    });

    test('returns input when missing @', () {
      expect(UserSearchHelper.obfuscateEmail('not-an-email'), 'not-an-email');
    });

    test('returns input when @ is first character', () {
      expect(UserSearchHelper.obfuscateEmail('@gmail.com'), '@gmail.com');
    });

    test('trims whitespace before obfuscating', () {
      expect(
        UserSearchHelper.obfuscateEmail('  ana@example.org  '),
        'a***@example.org',
      );
    });
  });
}
