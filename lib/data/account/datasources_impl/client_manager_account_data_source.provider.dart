import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';
import 'package:twake_chat/data/account/datasources_impl/client_manager_account_data_source.dart';

part 'client_manager_account_data_source.provider.g.dart';

@Riverpod(keepAlive: true)
AccountClientDataSource accountClientDataSource(Ref ref) =>
    ClientManagerAccountDataSource();
