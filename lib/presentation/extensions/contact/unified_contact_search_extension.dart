import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';

extension UnifiedContactsSearch on Iterable<UnifiedContact> {
  /// Contacts whose name, Matrix ID, email or phone matches [keyword],
  /// ignoring case and diacritics ("elise" finds "Élise" and the other way
  /// round). The matching rules are the ones the legacy contact lists used, so
  /// every list of the app searches the same way. An empty keyword matches all.
  List<UnifiedContact> searchContacts(String keyword) {
    final needle = keyword.trim();
    if (needle.isEmpty) return toList(growable: false);

    return const SearchEngine().matchAnyField(
      needle,
      toList(growable: false),
      fieldExtractors: [
        (UnifiedContact c) => [c.resolvedDisplayName ?? ''],
        (UnifiedContact c) => [c.matrixId],
        (UnifiedContact c) => c.emails,
        (UnifiedContact c) => c.phones,
      ],
      options: const SearchOptions(diacriticSensitive: false),
    );
  }
}
