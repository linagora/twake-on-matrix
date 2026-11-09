import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource/spaces/folded_spaces_datasource.dart';
import 'package:twake_chat/data/datasource_impl/spaces/folded_spaces_datasource.provider.dart';
import 'package:twake_chat/providers/room_list/folded_spaces_controller.dart';

import 'folded_spaces_controller_test.mocks.dart';
import '../fake_active_account.dart';

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  const user = '@me:own.org';
  const key = 'twake-chat.folded-spaces:$user';

  Future<ProviderContainer> load() async {
    final client = MockClient();
    when(client.userID).thenReturn(user);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverridesFollowing(),
    );
    container.read(fakeActiveAccountProvider.notifier).set(client);
    container.listen(foldedSpacesControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  group('FoldedSpacesController', () {
    test('whenBuilt_readsWhatWasFoldedForThisAccount', () async {
      SharedPreferences.setMockInitialValues({
        key: ['!s'],
        'twake-chat.folded-spaces:@other:own.org': ['!x'],
      });

      final container = await load();

      expect(container.read(foldedSpacesControllerProvider).value, {'!s'});
    });

    test('toggle_always_keepsTheChoice', () async {
      SharedPreferences.setMockInitialValues({});
      final container = await load();
      final controller = container.read(
        foldedSpacesControllerProvider.notifier,
      );
      final prefs = await SharedPreferences.getInstance();

      await controller.toggle('!s');
      expect(container.read(foldedSpacesControllerProvider).value, {'!s'});
      expect(prefs.getStringList(key), ['!s']);

      await controller.toggle('!s');
      expect(container.read(foldedSpacesControllerProvider).value, isEmpty);
      expect(prefs.getStringList(key), isEmpty);
    });

    test('toggle_whenStoredChoiceIsNotReadYet_keepsIt', () async {
      SharedPreferences.setMockInitialValues({
        key: ['!a', '!b'],
      });
      final client = MockClient();
      when(client.userID).thenReturn(user);
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: activeAccountOverridesFollowing(),
      );
      container.read(fakeActiveAccountProvider.notifier).set(client);
      container.listen(foldedSpacesControllerProvider, (_, _) {});

      await container
          .read(foldedSpacesControllerProvider.notifier)
          .toggle('!s');

      expect(container.read(foldedSpacesControllerProvider).value, {
        '!a',
        '!b',
        '!s',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(key), unorderedEquals(['!a', '!b', '!s']));
    });

    test('whenStoredValueHasTheWrongType_foldsNothing', () async {
      SharedPreferences.setMockInitialValues({key: 'oops'});

      final container = await load();

      expect(container.read(foldedSpacesControllerProvider).value, isEmpty);
    });

    test('toggle_whenWriteFails_keepsTheFoldForTheSession', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          ...activeAccountOverridesFollowing(),
          foldedSpacesDatasourceProvider.overrideWithValue(
            const _FailingWrite(),
          ),
        ],
      );
      final client = MockClient();
      when(client.userID).thenReturn(user);
      container.read(fakeActiveAccountProvider.notifier).set(client);
      container.listen(foldedSpacesControllerProvider, (_, _) {});
      await pumpEventQueue();

      await container
          .read(foldedSpacesControllerProvider.notifier)
          .toggle('!s');

      expect(container.read(foldedSpacesControllerProvider).value, {'!s'});
    });

    test('whenNoAccount_foldsNothing', () async {
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: activeAccountOverridesFollowing(),
      );
      container.listen(foldedSpacesControllerProvider, (_, _) {});
      await pumpEventQueue();

      expect(container.read(foldedSpacesControllerProvider).value, isEmpty);
    });
  });
}

class _FailingWrite implements FoldedSpacesDatasource {
  const _FailingWrite();

  @override
  Future<Set<String>> read(String userId) async => const {};

  @override
  Future<void> write(String userId, Set<String> spaceIds) async =>
      throw Exception('disk full');
}
