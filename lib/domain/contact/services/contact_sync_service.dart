import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/repositories/unified_contact_repository.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/delete_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';

/// Centralises every contact operation.
///
/// Pure Dart orchestration: it owns no state of its own and never talks to an
/// external system directly — it delegates to the use cases and the
/// repository. Controllers and legacy consumers must go through it instead of
/// reaching into `ContactsManager` or the SDK.
class ContactSyncService {
  const ContactSyncService({
    required UnifiedContactRepository repository,
    required ContactResolutionPolicy policy,
    required SyncContactsUseCase syncContacts,
    required WatchUnifiedContactsUseCase watchUnifiedContacts,
    required GetUnifiedContactUseCase getUnifiedContact,
    required AddContactUseCase addContact,
    required DeleteContactUseCase deleteContact,
  }) : _repository = repository,
       _policy = policy,
       _syncContacts = syncContacts,
       _watchUnifiedContacts = watchUnifiedContacts,
       _getUnifiedContact = getUnifiedContact,
       _addContact = addContact,
       _deleteContact = deleteContact;

  final UnifiedContactRepository _repository;
  final ContactResolutionPolicy _policy;
  final SyncContactsUseCase _syncContacts;
  final WatchUnifiedContactsUseCase _watchUnifiedContacts;
  final GetUnifiedContactUseCase _getUnifiedContact;
  final AddContactUseCase _addContact;
  final DeleteContactUseCase _deleteContact;

  /// Local-first: callers should render the current store immediately and let
  /// [refresh] run in the background.
  Future<void> initialSync() => refresh();

  Future<void> refresh() async {
    await _syncContacts.execute();
  }

  Stream<List<UnifiedContact>> watchContacts() =>
      _watchUnifiedContacts.execute();

  Future<UnifiedContact?> getContact(String matrixId) =>
      _getUnifiedContact.execute(matrixId);

  Future<void> addContact({
    required String matrixId,
    String? displayName,
    List<String> emails = const <String>[],
    List<String> phones = const <String>[],
  }) async {
    final contact = _policy.resolve(
      matrixId: matrixId,
      values: [
        ContactSourceValue(
          kind: ContactSourceKind.manual,
          displayName: displayName,
          emails: emails,
          phones: phones,
          updatedAt: DateTime.now().toUtc(),
        ),
      ],
    );
    await _addContact.execute(contact);
  }

  Future<void> deleteContact(String matrixId) =>
      _deleteContact.execute(matrixId);

  Future<void> clear() => _repository.clear();
}
