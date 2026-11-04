import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

abstract class CallMediaDatasource {
  Future<void> connect(
    CallServer server, {
    required bool isMicrophoneOn,
    required bool isCameraOn,
  });

  Future<void> disconnect();

  Future<void> setMicrophone({required bool isOn});

  Future<void> setCamera({required bool isOn});

  Stream<List<CallParticipant>> watchParticipants();

  Future<void> dispose();
}
