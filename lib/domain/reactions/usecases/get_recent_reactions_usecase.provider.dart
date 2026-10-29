import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/reactions/reactions_repository.provider.dart';
import 'package:twake_chat/domain/reactions/usecases/get_recent_reactions_usecase.dart';

part 'get_recent_reactions_usecase.provider.g.dart';

@riverpod
GetRecentReactionsUseCase getRecentReactionsUseCase(Ref ref) =>
    GetRecentReactionsUseCase(ref.watch(reactionsRepositoryProvider));
