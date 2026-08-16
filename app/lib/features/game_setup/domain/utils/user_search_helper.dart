class UserSearchHelper {
  const UserSearchHelper._();

  /// Obfuscates an email as first letter + *** + @domain.
  /// Example: juanmigrau@gmail.com -> j***@gmail.com
  static String obfuscateEmail(String email) {
    final trimmed = email.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0 || atIndex == trimmed.length - 1) {
      return trimmed;
    }
    final local = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);
    if (local.isEmpty) {
      return trimmed;
    }
    return '${local[0]}***$domain';
  }
}
