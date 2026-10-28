import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

part 'store_provider.g.dart';

/// The key-value store the account sources persist to.
@Riverpod(keepAlive: true)
Store store(Ref ref) => Store();
