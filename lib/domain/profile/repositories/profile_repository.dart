import 'package:twake_chat/domain/profile/entities/account_profile.dart';

abstract class ProfileRepository {
  /// Null when the user is unknown or cannot be reached; with [fresh], also
  /// when the server does not answer.
  Future<AccountProfile?> fetchProfile(String userId, {bool fresh = false});

  /// The profile of every logged-in account, in the order they were added.
  Future<List<AccountProfile>> fetchAccountProfiles();
}
