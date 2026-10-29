import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/reactions/reactions_repository.provider.dart';
import 'package:twake_chat/domain/reactions/usecases/store_recent_reactions_usecase.dart';

part 'store_recent_reactions_usecase.provider.g.dart';

@riverpod
StoreRecentReactionsUseCase storeRecentReactionsUseCase(Ref ref) =>
    StoreRecentReactionsUseCase(ref.watch(reactionsRepositoryProvider));
