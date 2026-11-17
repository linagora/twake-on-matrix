import 'package:twake_chat/domain/model/call/call_media_key.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_participant.dart';

abstract class CallMediaDatasource {
  Future<void> connect(CallServer server, CallMediaState media);

  Future<void> setMediaKey(CallMediaKey key);

  Future<void> disconnect();

  Future<void> setMicrophone({required bool isOn});

  Stream<List<CallParticipant>> watchParticipants();

  Future<void> dispose();
}
