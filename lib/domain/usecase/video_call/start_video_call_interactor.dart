import 'dart:async';

import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/domain/repository/video_call/video_call_repository.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.dart';

class StartVideoCallInteractor {
  const StartVideoCallInteractor(this._videoCallRepository, this._slugService);

  final VideoCallRepository _videoCallRepository;
  final VideoCallSlugService _slugService;

  /// Completes once the call link is known, without waiting for the message
  /// to be sent. Throws a `VideoCallRoomCreationFailedException` when the room
  /// cannot be created: nothing is sent then.
  Future<void> execute({
    required String roomId,
    required String baseUrl,
    required String startedTitle,
  }) async {
    final url = '$baseUrl/${await _createSlug()}';
    unawaited(
      _videoCallRepository.sendCallMessage(
        roomId: roomId,
        url: url,
        body: '$startedTitle $url',
      ),
    );
  }

  Future<String> _createSlug() async {
    try {
      return await _videoCallRepository.createRoom();
    } on VideoCallRoomCreationUnavailableException {
      return _slugService.generate();
    }
  }
}
