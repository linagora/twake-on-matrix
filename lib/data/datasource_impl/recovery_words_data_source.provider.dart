import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/recovery_words_data_source.dart';
import 'package:twake_chat/data/datasource_impl/recovery_words_data_source_impl.dart';
import 'package:twake_chat/data/network/recovery_words/recovery_words_api.provider.dart';

part 'recovery_words_data_source.provider.g.dart';

@riverpod
RecoveryWordsDataSource recoveryWordsDataSource(Ref ref) =>
    RecoveryWordsDataSourceImpl(ref.watch(recoveryWordsApiProvider));
