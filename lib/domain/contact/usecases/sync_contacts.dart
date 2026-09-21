import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';

/// Fetches every source, merges the values through [ContactResolutionPolicy]
/// and persists the resulting [UnifiedContact]s.
///
/// A failing source never blocks the others: its values are simply skipped for
/// this run (the previous values remain in the store).
class SyncContactsUseCase {
  const SyncContactsUseCase({
    required UnifiedContactRepository repository,
    required ContactResolutionPolicy policy,
    required List<ContactSource> sources,
  }) : _repository = repository,
       _policy = policy,
       _sources = sources;

  final UnifiedContactRepository _repository;
  final ContactResolutionPolicy _policy;
  final List<ContactSource> _sources;

  Future<List<UnifiedContact>> execute() async {
    final results = await Future.wait(_sources.map(_safeFetch));

    final valuesByMatrixId = <String, List<ContactSourceValue>>{};
    for (final contacts in results) {
      for (final contact in contacts) {
        valuesByMatrixId
            .putIfAbsent(contact.matrixId, () => <ContactSourceValue>[])
            .add(contact.value);
      }
    }

    final contacts = valuesByMatrixId.entries
        .map(
          (entry) => _policy.resolve(matrixId: entry.key, values: entry.value),
        )
        .toList(growable: false);

    if (contacts.isNotEmpty) {
      await _repository.upsertAll(contacts);
    }
    return contacts;
  }

  Future<List<SourcedContact>> _safeFetch(ContactSource source) async {
    try {
      return await source.fetch();
    } catch (_) {
      return const <SourcedContact>[];
    }
  }
}
