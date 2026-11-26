import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/profile/datasources/account_profiles_datasource.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/utils/client_manager.dart';

final class AccountProfilesDatasourceImpl implements AccountProfilesDatasource {
  const AccountProfilesDatasourceImpl(this._registry);

  final AccountClientRegistry _registry;

  @override
  Future<List<AccountProfile>> fetchAccountProfiles() async {
    try {
      return await Future.wait(
        ClientManager.loggedIn(_registry.clients).map(_profileOf),
      );
    } catch (e, s) {
      Logs().e('AccountProfilesDatasourceImpl::fetchAccountProfiles', e, s);
      rethrow;
    }
  }

  static Future<AccountProfile> _profileOf(Client client) async {
    final profile = await client.fetchOwnProfile();
    return AccountProfile(
      userId: profile.userId,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
    );
  }
}
