import 'package:twake_chat/domain/model/drive/drive_picker_session.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_config.dart';
import 'package:twake_chat/domain/repository/drive/drive_session_repository.dart';

final fakeDrivePickerSession = DrivePickerSession(
  id: 'intent-1',
  url: Uri.parse('https://drive.example/intents/intent-1'),
);

const fakeDrivePickerConfig = DrivePickerConfig(
  linkAction: DrivePickerAction(label: 'Add as link'),
);

class FakeDriveSessionRepository implements DriveSessionRepository {
  FakeDriveSessionRepository({this.isBridgeAvailable = true, this.error});

  @override
  final bool isBridgeAvailable;
  final Object? error;
  int bridgeCalls = 0;

  @override
  Future<DrivePickerSession> createPickerSessionViaBridge(
    DrivePickerConfig config,
  ) async {
    bridgeCalls++;
    if (error != null) throw error!;
    return fakeDrivePickerSession;
  }

  @override
  Future<String> exchangeToken(Uri platformUrl, String idToken) =>
      throw UnimplementedError();

  @override
  Future<DrivePickerSession> createPickerSessionWithToken({
    required Uri platformUrl,
    required String accessToken,
    required DrivePickerConfig config,
  }) => throw UnimplementedError();
}
