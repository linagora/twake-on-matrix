import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource_impl/capabilities/server_capabilities_datasource_impl.dart';

class _FakeClient extends Fake implements Client {
  _FakeClient(this.json);

  final Map<String, Object?> json;

  @override
  Future<Capabilities> getCapabilities() async => Capabilities.fromJson(json);
}

ServerCapabilitiesDatasourceImpl _datasource(Map<String, Object?> json) =>
    ServerCapabilitiesDatasourceImpl(_FakeClient(json));

void main() {
  test('fetchProfileEditCapabilities_withNoCapability_allowsBoth', () async {
    // Arrange
    final datasource = _datasource({});

    // Act
    final result = await datasource.fetchProfileEditCapabilities();

    // Assert
    expect(result.canEditAvatar, isTrue);
    expect(result.canEditDisplayName, isTrue);
  });

  test(
    'fetchProfileEditCapabilities_withSetCapabilitiesDisabled_forbidsBoth',
    () async {
      // Arrange
      final datasource = _datasource({
        'm.set_avatar_url': {'enabled': false},
        'm.set_displayname': {'enabled': false},
      });

      // Act
      final result = await datasource.fetchProfileEditCapabilities();

      // Assert
      expect(result.canEditAvatar, isFalse);
      expect(result.canEditDisplayName, isFalse);
    },
  );

  test(
    'fetchProfileEditCapabilities_withProfileFieldsDisabled_forbidsBoth',
    () async {
      // Arrange
      final datasource = _datasource({
        'm.profile_fields': {'enabled': false},
      });

      // Act
      final result = await datasource.fetchProfileEditCapabilities();

      // Assert
      expect(result.canEditAvatar, isFalse);
      expect(result.canEditDisplayName, isFalse);
    },
  );

  test(
    'fetchProfileEditCapabilities_withAllowedList_allowsOnlyListed',
    () async {
      // Arrange
      final datasource = _datasource({
        'm.profile_fields': {
          'enabled': true,
          'allowed': ['displayname'],
        },
      });

      // Act
      final result = await datasource.fetchProfileEditCapabilities();

      // Assert
      expect(result.canEditAvatar, isFalse);
      expect(result.canEditDisplayName, isTrue);
    },
  );

  test(
    'fetchProfileEditCapabilities_withDisallowedList_forbidsListed',
    () async {
      // Arrange
      final datasource = _datasource({
        'm.profile_fields': {
          'enabled': true,
          'disallowed': ['displayname'],
        },
      });

      // Act
      final result = await datasource.fetchProfileEditCapabilities();

      // Assert
      expect(result.canEditAvatar, isTrue);
      expect(result.canEditDisplayName, isFalse);
    },
  );

  test('fetchProfileEditCapabilities_withNoClient_throws', () async {
    // Arrange
    const datasource = ServerCapabilitiesDatasourceImpl(null);

    // Act
    final result = datasource.fetchProfileEditCapabilities();

    // Assert
    await expectLater(result, throwsStateError);
  });
}
