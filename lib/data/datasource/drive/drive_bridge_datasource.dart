import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_response.dart';

abstract interface class DriveBridgeDatasource {
  bool get isAvailable;

  Future<DrivePickerSessionResponse> createPickerSession(
    DrivePickerSessionRequest request,
  );
}
