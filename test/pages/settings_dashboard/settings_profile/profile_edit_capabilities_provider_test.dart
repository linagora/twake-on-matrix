import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/profile_edit_capabilities_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

class _FakeClient extends Fake implements Client {
  _FakeClient(this.response);

  final Future<Capabilities> response;

  @override
  Future<Capabilities> getCapabilities() => response;
}

final _editable = Capabilities.fromJson({});

final _locked = Capabilities.fromJson({
  'm.profile_fields': {'enabled': false},
});

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(retry: (_, _) => null);
    container.listen(profileEditCapabilitiesProvider, (_, _) {});
  });

  void setClient(Client client) =>
      container.read(activeMatrixClientProvider.notifier).setClient(client);

  test('activeClientChange_afterLoad_fetchesFromNewClient', () async {
    // Arrange
    setClient(_FakeClient(Future.value(_editable)));
    final first = await container.read(profileEditCapabilitiesProvider.future);

    // Act
    setClient(_FakeClient(Future.value(_locked)));
    final second = await container.read(profileEditCapabilitiesProvider.future);

    // Assert
    expect(first.canEditAvatar, isTrue);
    expect(second.canEditAvatar, isFalse);
  });

  test('activeClientChange_whileLoading_ignoresStaleAnswer', () async {
    // Arrange
    final stale = Completer<Capabilities>();
    setClient(_FakeClient(stale.future));
    container.read(profileEditCapabilitiesProvider);

    // Act
    setClient(_FakeClient(Future.value(_locked)));
    final result = await container.read(profileEditCapabilitiesProvider.future);
    stale.complete(_editable);
    await pumpEventQueue();

    // Assert
    expect(result.canEditAvatar, isFalse);
    expect(
      container.read(profileEditCapabilitiesProvider).value?.canEditAvatar,
      isFalse,
    );
  });
}
