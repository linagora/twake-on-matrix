import 'package:fluffychat/domain/usecase/invitation/generate_invitation_link_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/send_invitation_interactor.dart';
import 'package:fluffychat/domain/usecase/invitation/store_invitation_status_interactor.dart';
import 'package:fluffychat/pages/contacts_tab/providers/contacts_invitation_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockSendInvitationInteractor extends Mock
    implements SendInvitationInteractor {}

class MockGenerateInvitationLinkInteractor extends Mock
    implements GenerateInvitationLinkInteractor {}

class MockStoreInvitationStatusInteractor extends Mock
    implements StoreInvitationStatusInteractor {}

void main() {
  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('invitation providers expose legacy get_it interactors', () {
    final sendInvitationInteractor = MockSendInvitationInteractor();
    final generateInvitationLinkInteractor =
        MockGenerateInvitationLinkInteractor();
    final storeInvitationStatusInteractor =
        MockStoreInvitationStatusInteractor();

    GetIt.instance.registerSingleton<SendInvitationInteractor>(
      sendInvitationInteractor,
    );
    GetIt.instance.registerSingleton<GenerateInvitationLinkInteractor>(
      generateInvitationLinkInteractor,
    );
    GetIt.instance.registerSingleton<StoreInvitationStatusInteractor>(
      storeInvitationStatusInteractor,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(sendInvitationInteractorProvider),
      same(sendInvitationInteractor),
    );
    expect(
      container.read(generateInvitationLinkInteractorProvider),
      same(generateInvitationLinkInteractor),
    );
    expect(
      container.read(storeInvitationStatusInteractorProvider),
      same(storeInvitationStatusInteractor),
    );
  });
}
