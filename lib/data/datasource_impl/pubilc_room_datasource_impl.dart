import 'package:fluffychat/data/datasource/pubic_room_datasource.dart';
import 'package:fluffychat/data/model/search/public_room_response.dart';
import 'package:fluffychat/data/network/search/public_room_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:matrix/matrix.dart';

class PublicRoomDatasourceImpl extends PublicRoomDatasource {
  final PublicRoomAPI _publicRoomAPI = getIt.get<PublicRoomAPI>();

  @override
  Future<PublicRoomResponse> search({
    PublicRoomQueryFilter? filter,
    String? server,
    int? limit,
  }) {
    return _publicRoomAPI.search(
      filter: filter,
      server: server,
      limit: limit,
    );
  }
}
