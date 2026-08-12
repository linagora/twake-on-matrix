import 'package:twake_chat/data/model/addressbook/address_book_request.dart';
import 'package:twake_chat/data/model/addressbook/address_book_response.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/tom_endpoint.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';

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
