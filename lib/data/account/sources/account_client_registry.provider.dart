import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';

part 'account_client_registry.provider.g.dart';

/// The `Client` of every known account; the only id to `Client` mapping.
@Riverpod(keepAlive: true)
AccountClientRegistry accountClientRegistry(Ref ref) => AccountClientRegistry();
