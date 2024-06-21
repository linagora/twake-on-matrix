import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/search/pre_search_state.dart';
import 'package:matrix/matrix.dart';

class PreSearchRecentContactsInteractor {
  PreSearchRecentContactsInteractor();

  Stream<Either<Failure, Success>> execute({
    required List<Room> allRooms,
    int limit = 5,
  }) async* {
    try {
      final directRooms = allRooms.where((room) => room.isDirectChat).toList();
      if (directRooms.isEmpty) {
        yield const Left(PreSearchRecentContactsEmpty());
        return;
      }
      final recentRooms =
          directRooms.getRange(0, min(directRooms.length, limit)).toList();

      yield Right(PreSearchRecentContactsSuccess(rooms: recentRooms));
    } catch (e) {
      yield Left(PreSearchRecentContactsFailed(exception: e));
    }
  }
}
