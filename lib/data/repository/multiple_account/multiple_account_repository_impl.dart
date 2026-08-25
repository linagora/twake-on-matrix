import 'package:twake_chat/data/datasource/multiple_account/multiple_account_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/multiple_account/multiple_account_repository.dart';

class MultipleAccountRepositoryImpl extends MultipleAccountRepository {
  final MultipleAccountDatasource _multipleAccountDatasource = getIt
      .get<MultipleAccountDatasource>();

  @override
  Future<String?> getPersistActiveAccount() {
    return _multipleAccountDatasource.getPersistActiveAccount();
  }

  @override
  Future<void> storePersistActiveAccount(String userId) {
    return _multipleAccountDatasource.storePersistActiveAccount(userId);
  }

  @override
  Future<void> deletePersistActiveAccount() {
    return _multipleAccountDatasource.deletePersistActiveAccount();
  }
}
