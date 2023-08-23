import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:matrix/matrix.dart';

extension PresentationSearchExtensions on ContactPresentationSearch {
  Future<Profile?> getProfile(Client client) async {
    if (matrixId == null) {
      return Future.error(Exception("MatrixId is null"));
    }
    try {
      final profile = await client.getProfileFromUserId(
        matrixId!,
        getFromRooms: false,
      );
      Logs().d("SearchController()::getProfiles(): ${profile.avatarUrl}");
      return profile;
    } catch (e) {
      return Profile(
        avatarUrl: null,
        displayName: displayName,
        userId: matrixId!,
      );
    }
  }
}
