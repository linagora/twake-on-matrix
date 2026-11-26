import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.provider.dart';
import 'package:twake_chat/domain/profile/usecases/fetch_account_profiles_usecase.dart';

part 'fetch_account_profiles_usecase.provider.g.dart';

@riverpod
FetchAccountProfilesUseCase fetchAccountProfilesUseCase(Ref ref) =>
    FetchAccountProfilesUseCase(ref.watch(profileRepositoryProvider));
