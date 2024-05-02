import 'package:fluffychat/data/datasource/pubic_room_datasource.dart';
import 'package:fluffychat/data/model/search/public_room_response.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/public_room_reposity.dart';
import 'package:matrix/matrix.dart';

class PublicRoomRepositoryImpl extends PublicRoomRepository {
  final PublicRoomDatasource _publicRoomDatasource =
      getIt.get<PublicRoomDatasource>();

  @override
  Future<PublicRoomResponse> search({
    PublicRoomQueryFilter? filter,
    String? server,
    int? limit,
  }) {
    return _publicRoomDatasource.search(
      filter: filter,
      server: server,
      limit: limit,
    );
  }
}
