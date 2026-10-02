import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/sources/contact_enricher.dart';
import 'package:twake_chat/domain/contact/sources/phonebook_resolver.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';

/// Centralises every contact operation.
///
/// Pure Dart orchestration: it owns no state of its own and never talks to an
/// external system directly — it delegates to the use cases and the
/// repository. Controllers and legacy consumers must go through it instead of
/// reaching into legacy managers or the SDK.
class ContactSyncService {
  const ContactSyncService({
    required String userId,
    required UnifiedContactRepository repository,
    required ContactResolutionPolicy policy,
    required SyncContactsUseCase syncContacts,
    required WatchUnifiedContactsUseCase watchUnifiedContacts,
    required GetUnifiedContactUseCase getUnifiedContact,
    required AddContactUseCase addContact,
    List<ContactEnricher> enrichers = const <ContactEnricher>[],
    PhonebookResolver? phonebookResolver,
  }) : _userId = userId,
       _repository = repository,
       _policy = policy,
       _syncContacts = syncContacts,
       _watchUnifiedContacts = watchUnifiedContacts,
       _getUnifiedContact = getUnifiedContact,
       _addContact = addContact,
       _enrichers = enrichers,
       _phonebookResolver = phonebookResolver;

  /// Matrix ID of the account that owns the contacts this service operates on.
  final String _userId;
  final UnifiedContactRepository _repository;
  final ContactResolutionPolicy _policy;
  final SyncContactsUseCase _syncContacts;
  final WatchUnifiedContactsUseCase _watchUnifiedContacts;
  final GetUnifiedContactUseCase _getUnifiedContact;
  final AddContactUseCase _addContact;
  final List<ContactEnricher> _enrichers;
  final PhonebookResolver? _phonebookResolver;

  /// Local-first: callers should render the current store immediately and let
  /// [refresh] run in the background.
  Future<void> initialSync() => refresh();

  /// Fetches every source and enriches the result.
  ///
  /// [resolvePhonebook] first associates the device phonebook with Matrix IDs
  /// (identity lookup + address book upload). It is opt-in: only the caller
  /// that knows the phonebook is readable (mobile, permission granted) asks
  /// for it, so a background refresh never triggers the lookup.
  Future<void> refresh({bool resolvePhonebook = false}) async {
    if (resolvePhonebook) await _resolvePhonebook();
    await _syncContacts.execute(_userId);
    for (final enricher in _enrichers) {
      // Enrichment is best-effort on top of the synced base data: a failing
      // enricher must not abort the refresh nor skip the remaining ones.
      try {
        await enricher.enrich(_userId);
      } catch (exception, stackTrace) {
        Logs().e(
          'ContactSyncService::refresh: enricher failed',
          exception,
          stackTrace,
        );
      }
    }
  }

  Future<void> _resolvePhonebook() async {
    try {
      await _phonebookResolver?.resolve(_userId);
    } catch (exception, stackTrace) {
      // Best effort: the sync below still reads the last stored resolution.
      Logs().e(
        'ContactSyncService::refresh: phonebook resolution failed',
        exception,
        stackTrace,
      );
    }
  }

  Stream<List<UnifiedContact>> watchContacts() =>
      _watchUnifiedContacts.execute(_userId);

  Future<UnifiedContact?> getContact(String matrixId) =>
      _getUnifiedContact.execute(_userId, matrixId);

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
    final existing = await _repository.getByMatrixId(_userId, matrixId);
    final retained = existing == null
        ? const <ContactSourceValue>[]
        : existing.sources
              .where((v) => v.kind != ContactSourceKind.manual)
              .toList(growable: false);

    final contact = _policy.resolve(
      matrixId: matrixId,
      values: [...retained, manual],
    );
    await _addContact.execute(_userId, contact);
  }

  Future<void> clear() => _repository.clear(_userId);
}
