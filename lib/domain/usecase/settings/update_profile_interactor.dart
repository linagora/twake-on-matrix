import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/settings/update_profile_failure.dart';
import 'package:fluffychat/domain/app_state/settings/update_profile_loading.dart';
import 'package:fluffychat/domain/app_state/settings/update_profile_success.dart';
import 'package:matrix/matrix.dart';

class UpdateProfileInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client client,
    Uri? avatarUrl,
    bool isDeleteAvatar = false,
    String? displayName,
  }) async* {
    yield const Right(UpdateProfileLoading());
    try {
      Logs().d(
        'UploadProfileInteractor::execute(): Uri - $avatarUrl - displayName - $displayName',
      );
      if (avatarUrl != null || isDeleteAvatar) {
        await client.setAvatarUrl(
          client.userID!,
          avatarUrl ?? Uri.parse(''),
        );
      }
      if (displayName != null) {
        await client.setDisplayName(
          client.userID!,
          displayName,
        );
      }
      if (isDeleteAvatar) {
        yield Right(
          DeleteProfileSuccess(
            displayName: displayName,
          ),
        );
        return;
      }
      yield Right(
        UpdateProfileSuccess(
          displayName: displayName,
          avatar: avatarUrl,
        ),
      );
    } catch (e) {
      Logs().d(
        'UploadAvatarInteractor::execute(): Exception - $e}',
      );
      yield Left(UpdateProfileFailure(e));
    }
  }
}
