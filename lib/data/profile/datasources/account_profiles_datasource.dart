import 'package:twake_chat/domain/profile/entities/account_profile.dart';

abstract class AccountProfilesDatasource {
  /// The profile of every logged-in account, in the order they were added.
  Future<List<AccountProfile>> fetchAccountProfiles();
}
