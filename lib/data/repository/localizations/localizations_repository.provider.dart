import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/localizations/localizations_datasource.provider.dart';
import 'package:twake_chat/data/repository/localizations/localizations_repository_impl.dart';
import 'package:twake_chat/domain/repository/localizations/localizations_repository.dart';

part 'localizations_repository.provider.g.dart';

@riverpod
LocalizationsRepository localizationsRepository(Ref ref) =>
    LocalizationsRepositoryImpl(ref.watch(localizationsDataSourceProvider));
