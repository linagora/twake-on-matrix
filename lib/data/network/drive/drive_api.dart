import 'package:dio/dio.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/drive/drive_json.dart';
import 'package:twake_chat/data/network/interceptor/drive_error_interceptor.dart';

class DriveApi {
  const DriveApi(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> post(
    Uri url, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
  }) async {
    final data = await runDriveRequest(
      () => _client.postToGetBody(
        url.toString(),
        data: body,
        options: Options(headers: headers),
      ),
    );
    return asJsonObject(data);
  }
}
