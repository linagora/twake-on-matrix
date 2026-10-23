import 'package:twake_chat/data/model/drive/drive_picker_action_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_response.dart';

final drivePickerSessionRequest = DrivePickerSessionRequest.pick(
  sharingLink: const DrivePickerActionRequest(label: 'Add as link'),
  downloadLink: const DrivePickerActionRequest(
    label: 'Add as attachment',
    maxFileSize: 1000,
    availableSize: 1000,
  ),
);

Map<String, dynamic> drivePickerSessionResponseJson({
  String id = 'intent-1',
  List<Map<String, String>>? services,
  String? client = 'twake-chat',
}) => {
  'data': {
    'id': id,
    'attributes': {
      'services':
          services ??
          [
            {'href': 'https://drive.example/intents/intent-1'},
          ],
      if (client != null) 'client': client,
    },
  },
};

DrivePickerSessionResponse fakeSessionResponse({
  String id = 'intent-1',
  String? href = 'https://drive.example/intents/intent-1',
}) => DrivePickerSessionResponse.fromJson(
  drivePickerSessionResponseJson(
    id: id,
    services: href == null
        ? const []
        : [
            {'href': href},
          ],
  ),
);
