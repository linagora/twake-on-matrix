import 'package:fluffychat/data/model/addressbook/address_book_request.dart';
import 'package:fluffychat/data/model/addressbook/address_book_response.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/tom_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';

class AddressBookApi {
  final DioClient _client = getIt.get<DioClient>(
    instanceName: NetworkDI.tomDioClientName,
  );

  Future<AddressbookResponse> getAddressBook() async {
    final response = await _client
        .get(TomEndpoint.addressbookServicePath.path)
        .onError((error, stackTrace) => throw Exception(error));

    return AddressbookResponse.fromJson(response);
  }

  Future<AddressbookResponse> updateAddressBook({
    required AddressBookRequest request,
  }) async {
    final response = await _client
        .postToGetBody(
          TomEndpoint.addressbookServicePath.path,
          data: request.toJson(),
        )
        .onError((error, stackTrace) => throw Exception(error));

    return AddressbookResponse.fromJson(response);
  }
}
