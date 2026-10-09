import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_response.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_request.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_response.dart';

abstract interface class DriveTokenDatasource {
  Future<DriveTokenExchangeResponse> exchangeToken(
    Uri platformUrl,
    DriveTokenExchangeRequest request,
  );

  Future<DrivePickerSessionResponse> createPickerSession({
    required Uri platformUrl,
    required String accessToken,
    required DrivePickerSessionRequest request,
  });
}
