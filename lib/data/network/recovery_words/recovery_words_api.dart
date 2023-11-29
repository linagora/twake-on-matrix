import 'package:dio/dio.dart';
import 'package:fluffychat/data/model/recovery_words_json.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/tom_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:matrix/matrix.dart';

class RecoveryWordsAPI {
  final DioClient _client =
      getIt.get<DioClient>(instanceName: NetworkDI.tomDioClientName);

  RecoveryWordsAPI();

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
      Logs().e('RecoveryWordsAPI::deleteRecoveryWords() [Exception]', error);
      throw Exception(error);
    });
    return _deleteRecoverySuccess(response?.statusCode);
  }

  bool _deleteRecoverySuccess(int? statusCode) {
    if (statusCode == null) return false;
    return statusCode >= 200 && statusCode <= 299 || statusCode == 404;
  }
}
