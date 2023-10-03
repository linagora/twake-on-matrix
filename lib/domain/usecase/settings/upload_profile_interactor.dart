import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/settings/upload_profile_failure.dart';
import 'package:fluffychat/domain/app_state/settings/upload_profile_loading.dart';
import 'package:fluffychat/domain/app_state/settings/upload_profile_success.dart';
import 'package:matrix/matrix.dart';

class UploadProfileInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client client,
    required String userId,
    Uri? avatarUrl,
    bool isUpdateDisPlayName = false,
    String? displayName,
  }) async* {
    yield const Right(UploadProfileLoading());
    try {
      Logs().d(
        'UploadAvatarInteractor::execute(): Uri - $avatarUrl - displayName - $displayName',
      );
      if (avatarUrl != null) {
        await client.setAvatarUrl(
          userId,
          avatarUrl,
        );
      }
      if (displayName != null) {
        await client.setDisplayName(userId, displayName);
      }
      yield Right(
        UploadProfileSuccess(
          displayName: displayName,
          avatar: avatarUrl,
        ),
      );
    } catch (e) {
      Logs().d(
        'UploadAvatarInteractor::execute(): Exception - $e}',
      );
      yield Left(UploadProfileFailure(e));
    }
  }
}
