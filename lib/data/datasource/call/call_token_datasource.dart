import 'package:twake_chat/data/model/call/sfu_token_request.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

abstract class CallTokenDatasource {
  Future<CallServer> fetchServer(String serviceUrl, SfuTokenRequest request);
}
