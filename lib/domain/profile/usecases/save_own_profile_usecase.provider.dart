import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.provider.dart';
import 'package:twake_chat/domain/profile/usecases/save_own_profile_usecase.dart';

part 'save_own_profile_usecase.provider.g.dart';

@riverpod
SaveOwnProfileUseCase saveOwnProfileUseCase(Ref ref) =>
    SaveOwnProfileUseCase(ref.watch(profileRepositoryProvider));
