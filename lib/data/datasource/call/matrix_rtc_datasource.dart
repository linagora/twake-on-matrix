import 'package:twake_chat/domain/model/call/call_models.dart';

abstract class MatrixRtcDatasource {
  CallRoomInfo getRoomInfo(String roomId);

  Future<CallServer> fetchServer({
    required String roomId,
    required String serviceUrl,
  });

  Future<void> endStaleOwnMembership(String roomId);

  /// The membership stays alive (delayed leave, expiry) until
  /// [leaveMembership].
  Future<void> joinMembership({
    required String roomId,
    required String serviceUrl,
    required bool isVideo,
  });

  Future<void> leaveMembership(String roomId);
}
