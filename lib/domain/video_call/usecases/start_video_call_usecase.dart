import 'dart:async';

import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/repository/video_call/video_call_repository.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.dart';

class StartVideoCallUseCase {
  const StartVideoCallUseCase(this._videoCallRepository, this._slugService);

  final VideoCallRepository _videoCallRepository;
  final VideoCallSlugService _slugService;

  /// Completes once the call link is known, without waiting for the message
  /// to be sent. Throws a `VideoCallRoomCreationFailedException` when the room
  /// cannot be created on [baseUrl]: nothing is sent then. Nothing is sent
  /// either when the user left [roomId] meanwhile.
  Future<void> execute({
    required String roomId,
    required String baseUrl,
    required String startedTitle,
  }) async {
    final url = '$baseUrl/${await _createSlug(baseUrl)}';
    if (!_videoCallRepository.isJoined(roomId)) return;
    unawaited(
      _videoCallRepository.sendCallMessage(
        roomId: roomId,
        url: url,
        body: '$startedTitle $url',
      ),
    );
  }

  Future<String> _createSlug(String baseUrl) async {
    final String roomUrl;
    try {
      roomUrl = await _videoCallRepository.createRoom();
    } on VideoCallRoomCreationUnavailableException {
      return _slugService.generate();
    }
    // Received call links are only shown when they are on the base url.
    final slug = _slugService.parse(roomUrl, baseUrl: baseUrl);
    if (slug == null) {
      throw VideoCallRoomCreationFailedException(
        cause: FormatException('Unusable room url', roomUrl),
      );
    }
    return slug;
  }
}
