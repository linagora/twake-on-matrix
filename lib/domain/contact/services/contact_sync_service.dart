import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_session.dart';
import 'package:twake_chat/domain/contact/sources/contact_enricher.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/delete_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';

/// Centralises every contact operation.
///
/// Pure Dart orchestration: it owns the current sync session and never talks to an
/// external system directly — it delegates to the use cases and the
/// repository. Controllers and legacy consumers must go through it instead of
/// reaching into `ContactsManager` or the SDK.
/// Groups the contact use cases to keep the service constructor small.
class ContactUseCases {
  const ContactUseCases({
    required this.sync,
    required this.watch,
    required this.get,
    required this.add,
    required this.delete,
  });

  final SyncContactsUseCase sync;
  final WatchUnifiedContactsUseCase watch;
  final GetUnifiedContactUseCase get;
  final AddContactUseCase add;
  final DeleteContactUseCase delete;
}

class ContactSyncService {
  ContactSyncService({
    required UnifiedContactRepository repository,
    required ContactResolutionPolicy policy,
    required ContactUseCases useCases,
    List<ContactEnricher> enrichers = const <ContactEnricher>[],
    ContactMutationQueue? mutations,
    bool enabled = true,
  }) : _repository = repository,
       _policy = policy,
       _useCases = useCases,
       _enrichers = enrichers,
       _mutations = mutations ?? ContactMutationQueue() {
    _session = ContactSyncSession(_mutations);
    if (!enabled) dispose();
  }

  final UnifiedContactRepository _repository;
  final ContactResolutionPolicy _policy;
  final ContactUseCases _useCases;
  final List<ContactEnricher> _enrichers;
  final ContactMutationQueue _mutations;
  late ContactSyncSession _session;
  Future<void>? _refresh;
  Future<void>? _clearing;
  bool _disposed = false;

  /// Local-first: callers should render the current store immediately and let
  /// [refresh] run in the background.
  Future<void> initialSync() => refresh();

  Future<void> refresh() {
    if (_disposed) return Future<void>.value();
    if (_refresh != null) return _refresh!;
    late final Future<void> refresh;
    refresh = _runRefresh(_session).whenComplete(() {
      if (identical(_refresh, refresh)) _refresh = null;
    });
    return _refresh = refresh;
  }

  Future<void> _runRefresh(ContactSyncSession session) async {
    await _clearing;
    if (!session.isActive) return;
    await _syncContacts.execute(session: session);
    for (final enricher in _enrichers) {
      if (!session.isActive) return;
      await enricher.enrich(session: session);
    }
  }

  Stream<List<UnifiedContact>> watchContacts() =>
      _disposed ? Stream.value(const []) : _useCases.watch.execute();

  Future<UnifiedContact?> getContact(String matrixId) =>
      _disposed ? Future.value() : _useCases.get.execute(matrixId);

  Future<void> addContact({
    required String matrixId,
    String? displayName,
    List<String> emails = const <String>[],
    List<String> phones = const <String>[],
  }) async {
    final manual = ContactSourceValue(
      kind: ContactSourceKind.manual,
      displayName: displayName,
      emails: emails,
      phones: phones,
      updatedAt: DateTime.now().toUtc(),
    );

    // Retain previously stored source values (synced, phonebook, …) and
    // replace only the manual entry so a later sync does not discard user data.
    final existing = await _repository.getByMatrixId(matrixId);
    final retained = existing == null
        ? const <ContactSourceValue>[]
        : existing.sources
              .where((v) => v.kind != ContactSourceKind.manual)
              .toList(growable: false);

    final contact = _policy.resolve(
      matrixId: matrixId,
      values: [...retained, manual],
    );
    await _session.mutate(() => _useCases.add.execute(contact));
  }

  Future<void> deleteContact(String matrixId) =>
      _session.mutate(() => _useCases.delete.execute(matrixId));

  Future<void> clear() {
    if (_clearing != null) return _clearing!;
    _session.invalidate();
    _refresh = null;
    if (!_disposed) _session = ContactSyncSession(_mutations);
    return _clearing = _clear();
  }

  Future<void> _clear() async {
    try {
      await _mutations.run(_repository.clear);
    } finally {
      _clearing = null;
    }
  }

  void dispose() {
    _disposed = true;
    _session.invalidate();
  }
}
