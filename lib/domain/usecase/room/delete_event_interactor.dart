import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/delete_event_state.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:matrix/matrix.dart';

class DeleteEventInteractor {
  Stream<Either<Failure, Success>> execute(Event event) async* {
    // Error-status events never reached the server — remove locally only.
    if (event.status.isError) {
      yield* _removeLocalEvent(event);
      return;
    }

    if (!event.canDelete) {
      yield Left(NoPermissionToDeleteEvent());
      return;
    }

    try {
      await event.redactEvent();
    } catch (e) {
      yield Left(DeleteEventFailure());
      return;
    }

    yield* _removeLocalEvent(event);
  }

  Stream<Either<Failure, Success>> _removeLocalEvent(Event event) async* {
    try {
      await event.remove();
      yield Right(DeleteEventSuccess());
    } catch (e) {
      yield Left(RemoveLocalEventFailure());
    }
  }
}
