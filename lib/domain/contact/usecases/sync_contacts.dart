import 'package:matrix/matrix.dart';
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
/// Values whose kind is produced by no source (enrichers, e.g. TOM user_info)
/// survive the sync as long as the contact itself does, so an enrichment pass
/// is not wiped — and refetched — on every refresh.
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
      _sources.map((source) => _safeFetch(source, userId, failedKinds)),
    );

    final existing = await _repository.getContacts(userId);
    final outcome = _reconcile(
      fetched: _groupByMatrixId(results),
      existing: {for (final contact in existing) contact.matrixId: contact},
      failedKinds: failedKinds,
      refreshedKinds: {
        for (final source in _sources)
          if (!failedKinds.contains(source.kind)) source.kind,
      },
    );

    if (outcome.contacts.isNotEmpty) {
      await _repository.upsertAll(userId, outcome.contacts);
    }
    for (final matrixId in outcome.removedMatrixIds) {
      await _repository.delete(userId, matrixId);
    }
    return outcome.contacts;
  }

  /// Rebuilds every contact from the fetched and stored values.
  ///
  /// A contact without any remaining value is reported as removed instead of
  /// being resolved.
  ({List<UnifiedContact> contacts, List<String> removedMatrixIds}) _reconcile({
    required Map<String, List<ContactSourceValue>> fetched,
    required Map<String, UnifiedContact> existing,
    required Set<ContactSourceKind> failedKinds,
    required Set<ContactSourceKind> refreshedKinds,
  }) {
    final contacts = <UnifiedContact>[];
    final removedMatrixIds = <String>[];

    for (final matrixId in {...fetched.keys, ...existing.keys}) {
      final values = _mergeValues(
        stored: existing[matrixId],
        fetched: fetched[matrixId],
        failedKinds: failedKinds,
        refreshedKinds: refreshedKinds,
      );
      if (values.isEmpty) {
        removedMatrixIds.add(matrixId);
      } else {
        contacts.add(_policy.resolve(matrixId: matrixId, values: values));
      }
    }

    return (contacts: contacts, removedMatrixIds: removedMatrixIds);
  }

  Map<String, List<ContactSourceValue>> _groupByMatrixId(
    List<List<SourcedContact>> results,
  ) {
    final byMatrixId = <String, List<ContactSourceValue>>{};
    for (final contacts in results) {
      for (final contact in contacts) {
        byMatrixId
            .putIfAbsent(contact.matrixId, () => <ContactSourceValue>[])
            .add(contact.value);
      }
    }
    return byMatrixId;
  }

  /// Merges the values fetched in this run with the stored ones that cannot be
  /// refreshed: manual entries are never fetched, and failed sources keep their
  /// last known values. Values from a successful source are dropped so that a
  /// deletion propagates to the store. Enrichment values (a kind no source
  /// produces, e.g. TOM user_info) are retained only when the contact still
  /// exists, so a contact dropped by every source does not linger as an
  /// enrichment-only zombie.
  List<ContactSourceValue> _mergeValues({
    required UnifiedContact? stored,
    required List<ContactSourceValue>? fetched,
    required Set<ContactSourceKind> failedKinds,
    required Set<ContactSourceKind> refreshedKinds,
  }) {
    final values = <ContactSourceValue>[];
    final retainedEnrichment = <ContactSourceValue>[];

    for (final value in stored?.sources ?? const <ContactSourceValue>[]) {
      if (refreshedKinds.contains(value.kind)) continue;
      if (value.kind == ContactSourceKind.manual ||
          failedKinds.contains(value.kind)) {
        values.add(value);
      } else {
        retainedEnrichment.add(value);
      }
    }
    values.addAll(fetched ?? const <ContactSourceValue>[]);
    if (values.isNotEmpty) values.addAll(retainedEnrichment);
    return values;
  }

  Future<List<SourcedContact>> _safeFetch(
    ContactSource source,
    String userId,
    Set<ContactSourceKind> failedKinds,
  ) async {
    try {
      return await source.fetch(userId);
    } catch (exception, stackTrace) {
      Logs().e(
        'SyncContactsUseCase::_safeFetch: ${source.kind}',
        exception,
        stackTrace,
      );
      failedKinds.add(source.kind);
      return const <SourcedContact>[];
    }
  }
}
