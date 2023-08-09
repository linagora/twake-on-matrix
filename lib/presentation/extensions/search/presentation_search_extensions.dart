import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:matrix/matrix.dart';

extension PresentationSearchExtensions on ContactPresentationSearch {
  Future<ProfileInformation?> getProfile(Client client) async {
    if (matrixId == null) {
      return Future.error(Exception("MatrixId is null"));
    }
    try {
      final profile = await client.getUserProfile(matrixId!);
      Logs().d("SearchController()::getProfiles(): ${profile.avatarUrl}");
      return profile;
    } catch (e) {
      return ProfileInformation(avatarUrl: null, displayname: displayName);
    }
  }
}
