import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/recovery_words_data_source.provider.dart';
import 'package:twake_chat/data/repository/recovery_words_repository_impl.dart';
import 'package:twake_chat/domain/repository/recovery_words_repository.dart';

part 'recovery_words_repository.provider.g.dart';

@riverpod
RecoveryWordsRepository recoveryWordsRepository(Ref ref) =>
    RecoveryWordsRepositoryImpl(ref.watch(recoveryWordsDataSourceProvider));
