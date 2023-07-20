import 'package:fluffychat/data/datasource/recovery_words_data_source.dart';
import 'package:fluffychat/data/datasource_impl/recovery_words_data_source_impl.dart';
import 'package:fluffychat/data/network/recovery_words/recovery_words_api.dart';
import 'package:fluffychat/data/repository/recovery_words_repository_impl.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/repository/recovery_words_repository.dart';
import 'package:fluffychat/domain/usecases/get_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecases/save_recovery_words_interactor.dart';
import 'package:get_it/get_it.dart';

class RecoveryWordsDI extends BaseDI {
  @override
  String get scopeName => 'Recovery Words';

  @override
  void setUp(GetIt get) {
    _bindApi(get);
    _bindDataSource(get);
    _bindRepository(get);
    _bindInteractor(get);
  }

  void _bindApi(GetIt get) {
    get.registerLazySingleton<RecoveryWordsAPI>(() => RecoveryWordsAPI());
  }

  void _bindDataSource(GetIt get) {
    get.registerLazySingleton<RecoveryWordsDataSource>(
      () => RecoveryWordsDataSourceImpl(),
    );
  }

  void _bindRepository(GetIt get) {
    get.registerLazySingleton<RecoveryWordsRepository>(
        () => RecoveryWordsRepositoryImpl());
  }

  void _bindInteractor(GetIt get) {
    get.registerLazySingleton<GetRecoveryWordsInteractor>(
        () => GetRecoveryWordsInteractor());
    get.registerLazySingleton<SaveRecoveryWordsInteractor>(
        () => SaveRecoveryWordsInteractor());
  }
}
