/// Utilities for formatting account-related data
class AccountUtils {
  /// Formats a handle ensuring instance domain is present when possible.
  ///
  /// - If [acct] already contains a domain (username@domain), returns '@' + acct.
  /// - Else, tries to use [accountDomain], and if absent, [fallbackDomain].
  /// - If no domain is available, returns '@' + acct (username only).
  static String formatHandle({
    required String acct,
    String? username,
    String? accountDomain,
    String? fallbackDomain,
  }) {
    var handle = acct.trim();
    if (handle.isEmpty) {
      handle = (username ?? '').trim();
    }
    if (handle.isEmpty) {
      return '@';
    }
    if (handle.contains('@')) {
      return '@$handle';
    }

    final domain = (accountDomain?.trim().isNotEmpty ?? false)
        ? accountDomain!.trim()
        : (fallbackDomain ?? '').trim();

    if (domain.isNotEmpty) {
      return '@$handle@$domain';
    }
    return '@$handle';
  }
}
