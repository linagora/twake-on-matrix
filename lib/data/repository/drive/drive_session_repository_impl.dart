import 'package:twake_chat/data/datasource/drive/drive_bridge_datasource.dart';
import 'package:twake_chat/data/datasource/drive/drive_token_datasource.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_request.dart';
import 'package:twake_chat/data/repository/drive/drive_picker_mapper.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_session.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_config.dart';
import 'package:twake_chat/domain/repository/drive/drive_session_repository.dart';

class DriveSessionRepositoryImpl implements DriveSessionRepository {
  const DriveSessionRepositoryImpl(
    this._bridgeDatasource,
    this._tokenDatasource,
  );

  final DriveBridgeDatasource _bridgeDatasource;
  final DriveTokenDatasource _tokenDatasource;

  @override
  bool get isBridgeAvailable => _bridgeDatasource.isAvailable;

  @override
  Future<DrivePickerSession> createPickerSessionViaBridge(
    DrivePickerConfig config,
  ) async {
    final response = await _bridgeDatasource.createPickerSession(
      config.toRequest(),
    );
    return response.toDomain();
  }

  @override
  Future<String> exchangeToken(Uri platformUrl, String idToken) async {
    final response = await _tokenDatasource.exchangeToken(
      platformUrl,
      DriveTokenExchangeRequest.app(idToken: idToken),
    );
    return response.accessToken;
  }

  @override
  Future<DrivePickerSession> createPickerSessionWithToken({
    required Uri platformUrl,
    required String accessToken,
    required DrivePickerConfig config,
  }) async {
    final response = await _tokenDatasource.createPickerSession(
      platformUrl: platformUrl,
      accessToken: accessToken,
      request: config.toRequest(),
    );
    return response.toDomain();
  }
}
