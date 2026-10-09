import 'package:twake_chat/data/datasource/drive/drive_bridge_datasource.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_response.dart';
import 'package:twake_chat/data/network/drive/drive_bridge_api.dart';
import 'package:twake_chat/data/network/drive/drive_json.dart';
import 'package:twake_chat/data/network/drive_endpoint.dart';

class DriveBridgeDatasourceImpl implements DriveBridgeDatasource {
  const DriveBridgeDatasourceImpl(this._api);

  final DriveBridgeApi _api;

  @override
  bool get isAvailable => _api.isAvailable;

  @override
  Future<DrivePickerSessionResponse> createPickerSession(
    DrivePickerSessionRequest request,
  ) async {
    final json = await _api.post(
      DriveEndpoint.pickerSessionServicePath,
      body: request.toJson(),
    );
    return parseDriveJson(json, DrivePickerSessionResponse.fromJson);
  }
}
