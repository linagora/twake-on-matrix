import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';
import 'package:twake_chat/domain/public_rooms/usecases/get_public_room_preview_usecase.dart';

import '../fake_public_rooms_repository.dart';

void main() {
  test('execute_always_returnsThePreviewOfTheAddress', () async {
    // Arrange
    final repository = FakePublicRoomsRepository()
      ..preview = PublicRoomPreview.found(publicRoom('!a:hs'));

    // Act
    final preview = await GetPublicRoomPreviewUseCase(
      repository,
    ).execute('#a:hs');

    // Assert
    expect(preview, PublicRoomPreview.found(publicRoom('!a:hs')));
    expect(repository.previewQueries, ['#a:hs']);
  });

  test('execute_withoutClient_throwsNoClient', () async {
    // Arrange
    final repository = FakePublicRoomsRepository()
      ..previewError = const PublicRoomsNoClientException();

    // Act
    final result = GetPublicRoomPreviewUseCase(repository).execute('#a:hs');

    // Assert
    await expectLater(result, throwsA(isA<PublicRoomsNoClientException>()));
  });
}
