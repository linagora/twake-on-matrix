import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/dio_client.provider.dart';
import 'package:twake_chat/data/network/recovery_words/recovery_words_api.dart';

part 'recovery_words_api.provider.g.dart';

@riverpod
RecoveryWordsAPI recoveryWordsApi(Ref ref) =>
    RecoveryWordsAPI(ref.watch(legacyTomDioClientProvider));
