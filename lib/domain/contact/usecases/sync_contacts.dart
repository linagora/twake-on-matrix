import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';

/// Fetches every source, merges the values through [ContactResolutionPolicy]
/// and persists the resulting [UnifiedContact]s.
///
/// A failing source never blocks the others: its last known values are kept.
/// A source that succeeds is authoritative for its own kind, so the values it
/// no longer returns are dropped — a contact left without any value is deleted.
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

  Future<List<UnifiedContact>> execute(String userId) async {
    final failedKinds = <ContactSourceKind>{};
    final results = await Future.wait(
      _sources.map((source) => _safeFetch(source, failedKinds)),
    );

    final fetchedByMatrixId = <String, List<ContactSourceValue>>{};
    for (final contacts in results) {
      for (final contact in contacts) {
        fetchedByMatrixId
            .putIfAbsent(contact.matrixId, () => <ContactSourceValue>[])
            .add(contact.value);
      }
    }

    final existing = await _repository.getContacts(userId);
    final existingByMatrixId = {
      for (final contact in existing) contact.matrixId: contact,
    };

    // A stored value is kept only when this run cannot refresh its kind:
    // manual entries are never fetched, and failed sources keep their last
    // known values. Values from successful sources are dropped so that a
    // deletion propagates to the store.
    bool keep(ContactSourceValue value) =>
        value.kind == ContactSourceKind.manual ||
        failedKinds.contains(value.kind);

    final matrixIds = <String>{
      ...fetchedByMatrixId.keys,
      ...existingByMatrixId.keys,
    };

    final contacts = <UnifiedContact>[];
    final removedMatrixIds = <String>[];
    for (final matrixId in matrixIds) {
      final merged = <ContactSourceValue>[
        ...?existingByMatrixId[matrixId]?.sources.where(keep),
        ...?fetchedByMatrixId[matrixId],
      ];
      if (merged.isEmpty) {
        removedMatrixIds.add(matrixId);
      } else {
        contacts.add(_policy.resolve(matrixId: matrixId, values: merged));
      }
    }

    if (contacts.isNotEmpty) {
      await _repository.upsertAll(userId, contacts);
    }
    for (final matrixId in removedMatrixIds) {
      await _repository.delete(userId, matrixId);
    }
    return contacts;
  }

  Future<List<SourcedContact>> _safeFetch(
    ContactSource source,
    Set<ContactSourceKind> failedKinds,
  ) async {
    try {
      return await source.fetch();
    } catch (_) {
      failedKinds.add(source.kind);
      return const <SourcedContact>[];
    }
  }
}
