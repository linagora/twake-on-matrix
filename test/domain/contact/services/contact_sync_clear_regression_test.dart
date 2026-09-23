import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/usecases/add_contact.dart';
import 'package:twake_chat/domain/contact/usecases/delete_contact.dart';
import 'package:twake_chat/domain/contact/usecases/get_unified_contact.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';
import 'package:twake_chat/domain/contact/usecases/watch_unified_contacts.dart';

import '../fakes/fake_unified_contact_repository.dart';

class _DelayedSource implements ContactSource {
  final started = Completer<void>();
  final result = Completer<List<SourcedContact>>();

  @override
  ContactSourceKind get kind => ContactSourceKind.tomAddressBook;

  @override
  Future<List<SourcedContact>> fetch() {
    started.complete();
    return result.future;
  }
}

void main() {
  // Uses only the pre-session API, so this reproduces the bug on the baseline.
  test('clear remains empty when an earlier refresh completes', () async {
    final repository = FakeUnifiedContactRepository();
    addTearDown(repository.dispose);
    final source = _DelayedSource();
    const policy = ContactResolutionPolicy();
    final service = ContactSyncService(
      repository: repository,
      policy: policy,
      syncContacts: SyncContactsUseCase(
        repository: repository,
        policy: policy,
        sources: [source],
      ),
      watchUnifiedContacts: WatchUnifiedContactsUseCase(repository),
      getUnifiedContact: GetUnifiedContactUseCase(repository),
      addContact: AddContactUseCase(repository),
      deleteContact: DeleteContactUseCase(repository),
    );
    final refresh = service.refresh();
    await source.started.future;

    await service.clear();
    source.result.complete(const [
      SourcedContact(
        matrixId: '@alice:a',
        value: ContactSourceValue(kind: ContactSourceKind.tomAddressBook),
      ),
    ]);
    await refresh;

    expect(await repository.getContacts(), isEmpty);
  });
}
