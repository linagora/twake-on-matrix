import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';
import 'package:twake_chat/domain/model/public_rooms/room_address.dart';
import 'package:twake_chat/pages/public_rooms/preview/public_room_preview_controller.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';

import '../../../domain/public_rooms/fake_public_rooms_repository.dart';

void main() {
  const alias = '#general:hs';
  late FakePublicRoomsRepository repository;

  final provider = publicRoomPreviewControllerProvider(
    const RoomAddress(alias, via: ['hs2']),
  );

  Future<(ProviderContainer, PublicRoomPreviewController)> loaded(
    PublicRoomPreview preview,
  ) async {
    repository.preview = preview;
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [publicRoomsRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    return (container, container.read(provider.notifier));
  }

  setUp(() => repository = FakePublicRoomsRepository());

  test('build_always_loadsThePreviewOfTheAddress', () async {
    // Arrange
    final (container, _) = await loaded(
      PublicRoomPreview.found(publicRoom('!general:hs')),
    );

    // Act
    final state = container.read(provider).requireValue;

    // Assert
    expect(state.preview, PublicRoomPreview.found(publicRoom('!general:hs')));
    expect(repository.previewQueries, [alias]);
    expect(repository.previewVia, [
      ['hs2'],
    ]);
  });

  test('build_withoutClient_fails', () async {
    // Arrange
    repository.previewError = const PublicRoomsNoClientException();
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [publicRoomsRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(provider, (_, _) {});

    // Act
    final result = container.read(provider.future);

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomsNoClientException>()));
  });

  test('open_afterAFailedLookup_triesToJoin', () async {
    // Arrange
    repository.previewError = const PublicRoomsNoClientException();
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [publicRoomsRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(provider, (_, _) {});
    await expectLater(container.read(provider.future), throwsA(anything));

    // Act
    final result = await container.read(provider.notifier).open();

    // Assert
    expect(result, isA<PublicRoomJoined>());
    expect(repository.joinedIds, [alias]);
  });

  test('open_whenTheRoomIsOpen_joinsByTheAddress', () async {
    // Arrange
    final (container, controller) = await loaded(
      PublicRoomPreview.found(publicRoom('!general:hs')),
    );

    // Act
    final result = await controller.open();

    // Assert
    expect(result, isA<PublicRoomJoined>());
    expect((result as PublicRoomJoined).roomId, '!general:hs');
    expect(repository.joinedIds, [alias]);
    expect(repository.joinedVia, [
      ['hs2'],
    ]);
    expect(container.read(provider).requireValue.isPending, isFalse);
  });

  test('open_whenTheJoinIsNotInSyncYet_saysSo', () async {
    // Arrange
    repository.isJoinInSync = false;
    final (_, controller) = await loaded(
      PublicRoomPreview.found(publicRoom('!general:hs')),
    );

    // Act
    final result = await controller.open();

    // Assert
    expect(result, isA<PublicRoomJoinedNotInSync>());
  });

  test('open_whenUnavailable_triesToJoin', () async {
    // Arrange
    final (_, controller) = await loaded(const PublicRoomPreview.unavailable());

    // Act
    final result = await controller.open();

    // Assert
    expect(result, isA<PublicRoomJoined>());
    expect(repository.joinedIds, [alias]);
  });

  test('open_whenOnApproval_asksAndMarksRequested', () async {
    // Arrange
    final (container, controller) = await loaded(
      PublicRoomPreview.found(
        publicRoom('!general:hs', access: PublicRoomAccess.approval),
      ),
    );

    // Act
    final result = await controller.open();

    // Assert
    expect(result, isA<PublicRoomRequested>());
    expect(repository.knockedIds, [alias]);
    expect(repository.knockedVia, [
      ['hs2'],
    ]);
    expect(repository.joinedIds, isEmpty);
    final preview = container.read(provider).requireValue.preview;
    expect((preview as PublicRoomPreviewFound).isRequested, isTrue);
  });

  test('open_whenAlreadyRequested_isIgnored', () async {
    // Arrange
    final (_, controller) = await loaded(
      PublicRoomPreview.found(
        publicRoom('!general:hs', access: PublicRoomAccess.approval),
        isRequested: true,
      ),
    );

    // Act
    final result = await controller.open();

    // Assert
    expect(result, isA<PublicRoomOpenIgnored>());
    expect(repository.knockedIds, isEmpty);
  });

  test('open_whenBanned_isIgnored', () async {
    // Arrange
    final (_, controller) = await loaded(const PublicRoomPreview.banned());

    // Act
    final result = await controller.open();

    // Assert
    expect(result, isA<PublicRoomOpenIgnored>());
    expect(repository.joinedIds, isEmpty);
  });

  test('open_whilePending_ignoresASecondTap', () async {
    // Arrange
    repository.joinGate = Completer<void>();
    final (container, controller) = await loaded(
      PublicRoomPreview.found(publicRoom('!general:hs')),
    );
    final first = controller.open();

    // Act
    final second = await controller.open();

    // Assert
    expect(second, isA<PublicRoomOpenIgnored>());
    expect(container.read(provider).requireValue.isPending, isTrue);
    repository.joinGate!.complete();
    expect(await first, isA<PublicRoomJoined>());
  });

  test('open_whenTheJoinFails_saysItFailed', () async {
    // Arrange
    repository.joinError = PublicRoomJoinFailedException(
      cause: Exception('forbidden'),
    );
    final (container, controller) = await loaded(
      PublicRoomPreview.found(publicRoom('!general:hs')),
    );

    // Act
    final result = await controller.open();

    // Assert
    expect(result, isA<PublicRoomOpenFailed>());
    final state = container.read(provider).requireValue;
    expect(state.isPending, isFalse);
    expect(state.hasFailed, isTrue);
  });

  test('open_whenAlreadyJoined_isIgnored', () async {
    // Arrange
    final (_, controller) = await loaded(
      const PublicRoomPreview.joined('!general:hs'),
    );

    // Act
    final result = await controller.open();

    // Assert
    expect(result, isA<PublicRoomOpenIgnored>());
    expect(repository.joinedIds, isEmpty);
  });

  test('open_whenDisposedDuringTheKnock_stopsQuietly', () async {
    // Arrange
    repository.knockGate = Completer<void>();
    final (container, controller) = await loaded(
      PublicRoomPreview.found(
        publicRoom('!general:hs', access: PublicRoomAccess.approval),
      ),
    );
    final result = controller.open();

    // Act
    container.dispose();
    repository.knockGate!.complete();

    // Assert
    expect(await result, isA<PublicRoomRequested>());
  });
}
