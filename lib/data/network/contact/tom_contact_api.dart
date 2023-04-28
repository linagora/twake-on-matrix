import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/contact/lookup_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_mxid_response.dart';

class TomContactAPI {

  static final contactUrl = '${AppConfig.defaultIdentityServer}/_twake/identity/v1/lookup/match';

  final DioClient _client;

  TomContactAPI({
    required DioClient client,
  }): _client = client;

  Future<LookupMxidResponse> searchContacts(ContactQuery query) async {
    final requestBody = LookupMxidRequest(
      scopes: ['mail', 'uid', 'mobile'], 
      fields: ['uid', 'mobile', 'mail'], 
      val: query.keyword);
    
    final response = await _client.post(
      contactUrl,
      data: requestBody.toJson(),      
    );

    return LookupMxidResponse.fromJson(response);
  }
}