import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

part 'famedlysdk_store.provider.g.dart';

/// Kept alive: watched by the session-wide accountRepositoryProvider, and
/// the store only wraps the shared preferences instance.
@Riverpod(keepAlive: true)
Store store(Ref ref) => Store();
