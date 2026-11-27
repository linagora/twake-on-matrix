import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.provider.dart';
import 'package:twake_chat/domain/profile/usecases/fetch_own_profile_usecase.dart';

part 'fetch_own_profile_usecase.provider.g.dart';

@riverpod
FetchOwnProfileUseCase fetchOwnProfileUseCase(Ref ref) =>
    FetchOwnProfileUseCase(ref.watch(profileRepositoryProvider));
