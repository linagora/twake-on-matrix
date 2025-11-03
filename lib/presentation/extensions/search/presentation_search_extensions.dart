import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/presentation/extensions/user_info_extension.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info_manager.dart';
import 'package:matrix/matrix.dart';

extension PresentationSearchExtensions on ContactPresentationSearch {
  Future<Profile?> getProfile(Client client) async {
    if (matrixId == null) {
      return Future.error(Exception("MatrixId is null"));
    }
    try {
      final twakeProfile =
          await getIt.get<TwakeUserInfoManager>().getTwakeProfileFromUserId(
                client: client,
                userId: matrixId!,
              );
      Logs().d("SearchController()::getProfiles(): ${twakeProfile.avatarUrl}");
      return twakeProfile.toMatrixProfile();
    } catch (e) {
      return Profile(
        avatarUrl: null,
        displayName: displayName,
        userId: matrixId!,
      );
    }
  }
}
