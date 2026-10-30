import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/capabilities/server_capabilities_repository.provider.dart';
import 'package:twake_chat/domain/capabilities/exceptions/capabilities_exception.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';
import 'package:twake_chat/domain/capabilities/usecases/fetch_profile_edit_capabilities_usecase.provider.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';

class _FakeRepository implements ServerCapabilitiesRepository {
  _FakeRepository({this.result, this.error});

  final ProfileEditCapabilities? result;
  final Object? error;

  @override
  Future<ProfileEditCapabilities> fetchProfileEditCapabilities() async {
    final error = this.error;
    if (error != null) throw error;
    return result!;
  }
}

void main() {
  ProviderContainer createContainer(ServerCapabilitiesRepository repository) =>
      ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          serverCapabilitiesRepositoryProvider.overrideWithValue(repository),
        ],
      );

  test('execute_whenRepositorySucceeds_returnsCapabilities', () async {
    // Arrange
    const capabilities = ProfileEditCapabilities(
      canEditAvatar: false,
      canEditDisplayName: true,
    );
    final container = createContainer(_FakeRepository(result: capabilities));

    // Act
    final result = await container
        .read(fetchProfileEditCapabilitiesUseCaseProvider)
        .execute();

    // Assert
    expect(result, same(capabilities));
  });

  test('execute_whenRepositoryThrows_throwsTypedException', () async {
    // Arrange
    final cause = Exception('network');
    final container = createContainer(_FakeRepository(error: cause));

    // Act
    final result = container
        .read(fetchProfileEditCapabilitiesUseCaseProvider)
        .execute();

    // Assert
    await expectLater(
      result,
      throwsA(
        isA<FetchProfileEditCapabilitiesException>().having(
          (e) => e.cause,
          'cause',
          cause,
        ),
      ),
    );
  });
}
