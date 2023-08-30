import 'package:fluffychat/data/model/recovery_words_json.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/tom_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';

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
    return response.statusCode >= 200 && response.statusCode <= 299;
  }
}
