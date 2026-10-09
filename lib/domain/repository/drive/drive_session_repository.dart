import 'package:twake_chat/domain/model/drive/drive_picker_session.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_config.dart';

abstract interface class DriveSessionRepository {
  bool get isBridgeAvailable;

  Future<DrivePickerSession> createPickerSessionViaBridge(
    DrivePickerConfig config,
  );

  Future<String> exchangeToken(Uri platformUrl, String idToken);

  Future<DrivePickerSession> createPickerSessionWithToken({
    required Uri platformUrl,
    required String accessToken,
    required DrivePickerConfig config,
  });
}
