import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/search/pre_search_state.dart';
import 'package:matrix/matrix.dart';

class PreSearchRecentContactsInteractor {
  PreSearchRecentContactsInteractor();

  Stream<Either<Failure, Success>> execute({
    required List<Room> recentRooms,
    int? limit,
  }) async* {
    try {        
      final List<User> result = [];

      for (final room in recentRooms) {
        final users = room.getParticipants()
          .where((user) => user.membership.isInvite == true && user.displayName != null)
          .toSet();

        for (final user in users) {
          final isDuplicateUser = result
            .any((existingUser) => existingUser.id == user.id);

          if (!isDuplicateUser) {
            result.add(user);
          }

          if (result.length == limit) {
            break;
          }
        }

        if (result.length == limit) {
          break;
        }
      }
      if (result.isEmpty) {
        yield const Left(PreSearchRecentContactsEmpty());
      } else {
        yield Right(PreSearchRecentContactsSuccess(users: result));
      }
    } catch (e) {
      yield Left(PreSearchRecentContactsFailed(exception: e));
    }
  }
}