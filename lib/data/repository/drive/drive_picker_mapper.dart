import 'package:twake_chat/data/model/drive/drive_picker_action_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_response.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_session.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_config.dart';

extension DrivePickerActionMapper on DrivePickerAction {
  DrivePickerActionRequest toRequest() => DrivePickerActionRequest(
    label: label,
    maxFileSize: maxFileSize,
    availableSize: availableSize,
  );
}

extension DrivePickerConfigMapper on DrivePickerConfig {
  DrivePickerSessionRequest toRequest() => DrivePickerSessionRequest.pick(
    sharingLink: linkAction.toRequest(),
    downloadLink: attachmentAction?.toRequest(),
    isDark: isDark,
  );
}

extension DrivePickerSessionResponseMapper on DrivePickerSessionResponse {
  DrivePickerSession toDomain() {
    final url = Uri.tryParse(href ?? '');
    if (id.trim().isEmpty ||
        url == null ||
        !url.isScheme('https') ||
        url.host.isEmpty) {
      throw const FormatException(
        'Drive picker session needs an id and an https url',
      );
    }
    return DrivePickerSession(id: id, url: url, client: client);
  }
}
