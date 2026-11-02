import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/localizations/localizations_datasource.dart';
import 'package:twake_chat/data/datasource_impl/localizations/localizations_datasource_impl.dart';
import 'package:twake_chat/data/local/localizations/language_cache_manager.provider.dart';

part 'localizations_datasource.provider.g.dart';

@riverpod
LocalizationsDataSource localizationsDataSource(Ref ref) =>
    LocalizationsDataSourceImpl(ref.watch(languageCacheManagerProvider));
