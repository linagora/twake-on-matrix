import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';

import '../../../domain/contact/fakes/build_contact_sync_service.dart';
import '../../../domain/contact/fakes/fake_unified_contact_repository.dart';

void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;

  setUp(() {
    repository = FakeUnifiedContactRepository();
    service = buildContactSyncService(userId: userId, repository: repository);
  });

  tearDown(() => repository.dispose());

  test('unifiedContact returns the stored contact by matrixId', () async {
    await repository.upsert(
      userId,
      const UnifiedContact(
        matrixId: '@a:server',
        canonicalDisplayName: 'Alice',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        contactSyncServiceProvider.overrideWith((ref, _) => service),
      ],
    );
    addTearDown(container.dispose);

    final completer = Completer<void>();
    final subscription = container.listen(contactsControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasValue && !completer.isCompleted) completer.complete();
    }, fireImmediately: true);
    await completer.future;

    expect(
      container.read(unifiedContactProvider('@a:server'))?.resolvedDisplayName,
      'Alice',
    );
    expect(container.read(unifiedContactProvider('@missing:server')), isNull);
    subscription.close();
  });
}
