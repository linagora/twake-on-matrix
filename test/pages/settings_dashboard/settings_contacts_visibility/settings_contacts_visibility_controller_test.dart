import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/repository/user_info_repository.provider.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_controller.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import '../../../domain/user_info/fake_user_info_repository.dart';

const _userId = '@me:server';

class _FakeClient extends Fake implements Client {
  _FakeClient([this.userID = _userId]);

  @override
  final String? userID;
}

void main() {
  late FakeUserInfoRepository repository;
  late ProviderContainer container;

  setUp(() => repository = FakeUserInfoRepository());

  Future<SettingsContactsVisibilityState> load({
    bool loggedIn = true,
    String? visibility,
    List<VisibleEnum>? visibleFields,
  }) {
    repository.visibility = UserInfoVisibility(
      visibility: visibility,
      visibleFields: visibleFields,
    );
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [userInfoRepositoryProvider.overrideWithValue(repository)],
    );
    if (loggedIn) {
      container
          .read(activeMatrixClientProvider.notifier)
          .setClient(_FakeClient());
    }
    container.listen(settingsContactsVisibilityControllerProvider, (_, _) {});
    return container.read(settingsContactsVisibilityControllerProvider.future);
  }

  SettingsContactsVisibilityController controller() =>
      container.read(settingsContactsVisibilityControllerProvider.notifier);

  SettingsContactsVisibilityState? currentState() =>
      container.read(settingsContactsVisibilityControllerProvider).value;

  UserInfoVisibilityRequest sentRequest() => repository.updateCalls.single.$2;

  group('build', () {
    test('loads the visibility of the active account', () async {
      final state = await load(
        visibility: 'public',
        visibleFields: [VisibleEnum.email],
      );

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
      final state = await load(visibility: 'unknown');

      expect(
        state,
        const SettingsContactsVisibilityState(
          visibility: SettingsContactsVisibilityEnum.contacts,
        ),
      );
    });

    test('returns an empty state without an account', () async {
      final state = await load(loggedIn: false);

      expect(state, const SettingsContactsVisibilityState());
      expect(repository.getVisibilityCalls, isEmpty);
    });

    test('exposes the load error', () async {
      repository.error = Exception('network');

      await expectLater(load(), throwsA(isA<GetUserInfoVisibilityException>()));
      expect(
        container.read(settingsContactsVisibilityControllerProvider).hasError,
        isTrue,
      );
    });
  });

  group('selectVisibility', () {
    final cases = [
      (
        'private sends every field',
        'public',
        [VisibleEnum.email],
        SettingsContactsVisibilityEnum.private,
        [VisibleEnum.phone, VisibleEnum.email],
      ),
      (
        'public keeps the selected fields',
        'contacts',
        [VisibleEnum.email],
        SettingsContactsVisibilityEnum.public,
        [VisibleEnum.email],
      ),
      (
        'contacts selects every field when none was selected',
        'private',
        <VisibleEnum>[],
        SettingsContactsVisibilityEnum.contacts,
        [VisibleEnum.phone, VisibleEnum.email],
      ),
    ];
    for (final (name, from, fields, option, expectedFields) in cases) {
      test(name, () async {
        await load(visibility: from, visibleFields: fields);

        await controller().selectVisibility(option);

        expect(sentRequest().visibility, option.name);
        expect(sentRequest().visibleFields, expectedFields);
        expect(
          currentState(),
          SettingsContactsVisibilityState(
            visibility: option,
            visibleFields: expectedFields,
          ),
        );
      });
    }

    test('a failed update throws and keeps the state', () async {
      final before = await load(visibility: 'public');
      repository.error = Exception('network');

      await expectLater(
        controller().selectVisibility(SettingsContactsVisibilityEnum.private),
        throwsA(isA<UpdateUserInfoVisibilityException>()),
      );
      expect(currentState(), before);
    });

    test(
      'ignores a response for an account that is no longer active',
      () async {
        await load(visibility: 'public');
        repository.pendingUpdate = Completer<void>();
        final update = controller().selectVisibility(
          SettingsContactsVisibilityEnum.private,
        );

        repository.visibility = UserInfoVisibility(visibility: 'contacts');
        container
            .read(activeMatrixClientProvider.notifier)
            .setClient(_FakeClient('@other:server'));
        final otherState = await container.read(
          settingsContactsVisibilityControllerProvider.future,
        );
        repository.pendingUpdate!.complete();
        await update;

        expect(otherState.visibility, SettingsContactsVisibilityEnum.contacts);
        expect(currentState(), otherState);
      },
    );
  });

  group('toggleVisibleField', () {
    test('removes a selected field', () async {
      await load(
        visibility: 'public',
        visibleFields: [VisibleEnum.phone, VisibleEnum.email],
      );

      await controller().toggleVisibleField(VisibleEnum.phone);

      expect(sentRequest().visibility, 'public');
      expect(sentRequest().visibleFields, [VisibleEnum.email]);
    });

    test('adds a field to contacts when the load failed', () async {
      repository.error = Exception('network');
      await expectLater(load(), throwsException);
      repository.error = null;

      await controller().toggleVisibleField(VisibleEnum.email);

      expect(sentRequest().visibility, 'contacts');
      expect(sentRequest().visibleFields, [VisibleEnum.email]);
    });

    test('throws without an account', () async {
      await load(loggedIn: false);

      await expectLater(
        controller().toggleVisibleField(VisibleEnum.email),
        throwsA(isA<UpdateUserInfoVisibilityException>()),
      );
      expect(repository.updateCalls, isEmpty);
    });
  });
}
