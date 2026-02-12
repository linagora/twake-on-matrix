import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/delete_event_state.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:matrix/matrix.dart';

class DeleteEventInteractor {
  Stream<Either<Failure, Success>> execute(Event event) async* {
    if (!event.canDelete) {
      yield Left(NoPermissionToDeleteEvent());
    }

    try {
      await event.redactEvent();
    } catch (e) {
      yield Left(DeleteEventFailure());
      return;
    }

    try {
      await event.remove();
      yield Right(DeleteEventSuccess());
    } catch (e) {
      yield Left(RemoveLocalEventFailure());
    }
  }
}
