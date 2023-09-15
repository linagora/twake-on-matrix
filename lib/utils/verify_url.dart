import 'package:string_validator/string_validator.dart';

class VerifyUrl {
  static bool isValidLink(
    String link, {
    List<String> protocols = const ['http', 'https', 'ftp'],
    List<String> hostWhitelist = const [],
    List<String> hostBlacklist = const [],
    bool requireTld = true,
    bool requireProtocol = false,
    bool allowUnderscore = false,
  }) {
    if (link.isEmpty) return false;
    final Map<String, Object> options = {
      'require_tld': requireTld,
      'require_protocol': requireProtocol,
      'allow_underscores': allowUnderscore,
    };
    if (protocols.isNotEmpty) options['protocols'] = protocols;
    if (hostWhitelist.isNotEmpty) options['host_whitelist'] = hostWhitelist;
    if (hostBlacklist.isNotEmpty) options['host_blacklist'] = hostBlacklist;
    final isValid = isURL(link, options);
    return isValid;
  }
}
