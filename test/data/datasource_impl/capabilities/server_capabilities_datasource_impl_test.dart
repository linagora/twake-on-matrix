import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource_impl/capabilities/server_capabilities_datasource_impl.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';

class _FakeClient extends Fake implements Client {
  _FakeClient(this.json);

  final Map<String, Object?> json;

  @override
  Future<Capabilities> getCapabilities() async => Capabilities.fromJson(json);
}

Future<ProfileEditCapabilities> _read(Map<String, Object?> json) =>
    ServerCapabilitiesDatasourceImpl(
      _FakeClient(json),
    ).getProfileEditCapabilities();

void main() {
  test('getProfileEditCapabilities_withNoCapability_allowsBoth', () async {
    final result = await _read({});

    expect(result.canEditAvatar, isTrue);
    expect(result.canEditDisplayName, isTrue);
  });

  test(
    'getProfileEditCapabilities_withSetCapabilitiesDisabled_forbidsBoth',
    () async {
      final result = await _read({
        'm.set_avatar_url': {'enabled': false},
        'm.set_displayname': {'enabled': false},
      });

      expect(result.canEditAvatar, isFalse);
      expect(result.canEditDisplayName, isFalse);
    },
  );

  test(
    'getProfileEditCapabilities_withProfileFieldsDisabled_forbidsBoth',
    () async {
      final result = await _read({
        'm.profile_fields': {'enabled': false},
      });

      expect(result.canEditAvatar, isFalse);
      expect(result.canEditDisplayName, isFalse);
    },
  );

  test('getProfileEditCapabilities_withAllowedList_allowsOnlyListed', () async {
    final result = await _read({
      'm.profile_fields': {
        'enabled': true,
        'allowed': ['displayname'],
      },
    });

    expect(result.canEditAvatar, isFalse);
    expect(result.canEditDisplayName, isTrue);
  });

  test('getProfileEditCapabilities_withDisallowedList_forbidsListed', () async {
    final result = await _read({
      'm.profile_fields': {
        'enabled': true,
        'disallowed': ['displayname'],
      },
    });

    expect(result.canEditAvatar, isTrue);
    expect(result.canEditDisplayName, isFalse);
  });

  test('getProfileEditCapabilities_withNoClient_throws', () async {
    expect(
      const ServerCapabilitiesDatasourceImpl(null).getProfileEditCapabilities(),
      throwsStateError,
    );
  });
}
