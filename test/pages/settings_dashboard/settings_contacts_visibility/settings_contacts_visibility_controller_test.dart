import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/repository/user_info_repository.provider.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_controller.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import '../../../domain/user_info/fake_user_info_repository.dart';

const _userId = '@me:server';

class _FakeClient extends Fake implements Client {
  @override
  String? get userID => _userId;
}

void main() {
  late FakeUserInfoRepository repository;

  ProviderContainer createContainer({bool loggedIn = true}) {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [userInfoRepositoryProvider.overrideWithValue(repository)],
    );
    if (loggedIn) {
      container
          .read(activeMatrixClientProvider.notifier)
          .setClient(_FakeClient());
    }
    return container;
  }

  Future<SettingsContactsVisibilityState> load(ProviderContainer container) {
    container.listen(settingsContactsVisibilityControllerProvider, (_, _) {});
    return container.read(settingsContactsVisibilityControllerProvider.future);
  }

  SettingsContactsVisibilityController controllerOf(
    ProviderContainer container,
  ) => container.read(settingsContactsVisibilityControllerProvider.notifier);

  setUp(() => repository = FakeUserInfoRepository());

  group('build', () {
    test('loads the visibility of the active account', () async {
      repository.visibility = UserInfoVisibility(
        visibility: 'public',
        visibleFields: const [VisibleEnum.email],
      );

      final state = await load(createContainer());

      expect(repository.getVisibilityCalls, [_userId]);
      expect(
        state,
        const SettingsContactsVisibilityState(
          visibility: SettingsContactsVisibilityEnum.public,
          visibleFields: [VisibleEnum.email],
        ),
      );
    });

    test('falls back to contacts and no field for missing values', () async {
      repository.visibility = UserInfoVisibility(visibility: 'unknown');

      final state = await load(createContainer());

      expect(
        state,
        const SettingsContactsVisibilityState(
          visibility: SettingsContactsVisibilityEnum.contacts,
        ),
      );
    });

    test('returns an empty state without an account', () async {
      final state = await load(createContainer(loggedIn: false));

      expect(state, const SettingsContactsVisibilityState());
      expect(repository.getVisibilityCalls, isEmpty);
    });

    test('exposes the load error', () async {
      repository.error = Exception('network');
      final container = createContainer();

      await expectLater(
        load(container),
        throwsA(isA<GetUserInfoVisibilityException>()),
      );
      expect(
        container.read(settingsContactsVisibilityControllerProvider).hasError,
        isTrue,
      );
    });
  });

  group('selectVisibility', () {
    test('private sends every field', () async {
      repository.visibility = UserInfoVisibility(
        visibility: 'public',
        visibleFields: const [VisibleEnum.email],
      );
      final container = createContainer();
      await load(container);

      await controllerOf(
        container,
      ).selectVisibility(SettingsContactsVisibilityEnum.private);

      final request = repository.updateCalls.single.$2;
      expect(request.visibility, 'private');
      expect(request.visibleFields, [VisibleEnum.phone, VisibleEnum.email]);
      expect(
        container.read(settingsContactsVisibilityControllerProvider).value,
        const SettingsContactsVisibilityState(
          visibility: SettingsContactsVisibilityEnum.private,
          visibleFields: [VisibleEnum.phone, VisibleEnum.email],
        ),
      );
    });

    test('public keeps the selected fields', () async {
      repository.visibility = UserInfoVisibility(
        visibility: 'contacts',
        visibleFields: const [VisibleEnum.email],
      );
      final container = createContainer();
      await load(container);

      await controllerOf(
        container,
      ).selectVisibility(SettingsContactsVisibilityEnum.public);

      final request = repository.updateCalls.single.$2;
      expect(request.visibility, 'public');
      expect(request.visibleFields, [VisibleEnum.email]);
    });

    test('contacts selects every field when none was selected', () async {
      repository.visibility = UserInfoVisibility(visibility: 'private');
      final container = createContainer();
      await load(container);

      await controllerOf(
        container,
      ).selectVisibility(SettingsContactsVisibilityEnum.contacts);

      final request = repository.updateCalls.single.$2;
      expect(request.visibleFields, [VisibleEnum.phone, VisibleEnum.email]);
    });

    test('a failed update throws and keeps the state', () async {
      repository.visibility = UserInfoVisibility(visibility: 'public');
      final container = createContainer();
      final before = await load(container);
      repository.error = Exception('network');

      await expectLater(
        controllerOf(
          container,
        ).selectVisibility(SettingsContactsVisibilityEnum.private),
        throwsA(isA<UpdateUserInfoVisibilityException>()),
      );
      expect(
        container.read(settingsContactsVisibilityControllerProvider).value,
        before,
      );
    });
  });

  group('toggleVisibleField', () {
    test('removes a selected field', () async {
      repository.visibility = UserInfoVisibility(
        visibility: 'public',
        visibleFields: const [VisibleEnum.phone, VisibleEnum.email],
      );
      final container = createContainer();
      await load(container);

      await controllerOf(container).toggleVisibleField(VisibleEnum.phone);

      final request = repository.updateCalls.single.$2;
      expect(request.visibility, 'public');
      expect(request.visibleFields, [VisibleEnum.email]);
    });

    test('adds a field to contacts when the load failed', () async {
      repository.error = Exception('network');
      final container = createContainer();
      await expectLater(load(container), throwsException);
      repository.error = null;

      await controllerOf(container).toggleVisibleField(VisibleEnum.email);

      final request = repository.updateCalls.single.$2;
      expect(request.visibility, 'contacts');
      expect(request.visibleFields, [VisibleEnum.email]);
    });

    test('throws without an account', () async {
      final container = createContainer(loggedIn: false);
      await load(container);

      await expectLater(
        controllerOf(container).toggleVisibleField(VisibleEnum.email),
        throwsA(isA<UpdateUserInfoVisibilityException>()),
      );
      expect(repository.updateCalls, isEmpty);
    });
  });
}
