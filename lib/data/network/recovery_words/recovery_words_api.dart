import 'package:dio/dio.dart';
import 'package:twake_chat/data/model/recovery_words_json.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/tom_endpoint.dart';
import 'package:matrix/matrix.dart';

class RecoveryWordsAPI {
  const RecoveryWordsAPI(this._client);

  final DioClient _client;

  Future<RecoveryWordsResponse> getRecoveryWords() async {
    final response = await _client
        .get(TomEndpoint.recoveryWordsServicePath.path)
        .onError((error, stackTrace) => throw Exception(error));
    return RecoveryWordsResponse.fromJson(response);
  }

  Future<bool> saveRecoveryWords(String recoveryWords) async {
    final response = await _client
        .post(
          TomEndpoint.recoveryWordsServicePath.path,
          data: RecoveryWordsResponse(words: recoveryWords),
        )
        .onError((error, stackTrace) => throw Exception(error));
    return response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! <= 299;
  }

  Future<bool> deleteRecoveryWords() async {
    final options = Options(validateStatus: _deleteRecoverySuccess);
    final response = await _client
        .delete(TomEndpoint.recoveryWordsServicePath.path, options: options)
        .onError((error, stackTrace) {
          Logs().e(
            'RecoveryWordsAPI::deleteRecoveryWords() [Exception]',
            error,
          );
          throw Exception(error);
        });
    return _deleteRecoverySuccess(response?.statusCode);
  }

  bool _deleteRecoverySuccess(int? statusCode) {
    if (statusCode == null) return false;
    return statusCode >= 200 && statusCode <= 299 || statusCode == 404;
  }
}
