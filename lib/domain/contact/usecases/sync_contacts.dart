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

    final fetchedByMatrixId = <String, List<ContactSourceValue>>{};
    for (final contacts in results) {
      for (final contact in contacts) {
        fetchedByMatrixId
            .putIfAbsent(contact.matrixId, () => <ContactSourceValue>[])
            .add(contact.value);
      }
    }

    // Preserve values from sources that did not participate in this run
    // (e.g. a failed source or a manual entry added earlier).
    final existing = await _repository.getContacts();
    final existingByMatrixId = {
      for (final contact in existing) contact.matrixId: contact,
    };

    final contacts = <UnifiedContact>[];
    for (final entry in fetchedByMatrixId.entries) {
      final stored = existingByMatrixId[entry.key];
      final merged = <ContactSourceValue>[
        ..._storedValuesExcept(stored, entry.value),
        ...entry.value,
      ];
      contacts.add(_policy.resolve(matrixId: entry.key, values: merged));
    }

    if (contacts.isNotEmpty) {
      await _repository.upsertAll(contacts);
    }
    return contacts;
  }

  /// Keeps previously stored values whose source kind is absent from the
  /// current fetch (failed source, manual entry, etc.).
  List<ContactSourceValue> _storedValuesExcept(
    UnifiedContact? stored,
    List<ContactSourceValue> fetched,
  ) {
    if (stored == null) return const [];
    final fetchedKinds = {for (final v in fetched) v.kind};
    return stored.sources
        .where((v) => !fetchedKinds.contains(v.kind))
        .toList(growable: false);
  }

  Future<List<SourcedContact>> _safeFetch(ContactSource source) async {
    try {
      return await source.fetch();
    } catch (_) {
      return const <SourcedContact>[];
    }
  }
}
