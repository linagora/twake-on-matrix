import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.provider.dart';
import 'package:twake_chat/data/profile/datasources/account_profiles_datasource.dart';
import 'package:twake_chat/data/profile/datasources_impl/account_profiles_datasource_impl.dart';

part 'account_profiles_datasource_impl.provider.g.dart';

@riverpod
AccountProfilesDatasource accountProfilesDatasource(Ref ref) =>
    AccountProfilesDatasourceImpl(ref.watch(accountClientRegistryProvider));
