import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/local/localizations/language_cache_manager.dart';
import 'package:twake_chat/utils/famedlysdk_store.provider.dart';

part 'language_cache_manager.provider.g.dart';

@riverpod
LanguageCacheManager languageCacheManager(Ref ref) =>
    LanguageCacheManager(ref.watch(storeProvider));
