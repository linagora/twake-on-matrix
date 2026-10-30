import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/user_info_repository.provider.dart';
import 'package:twake_chat/domain/user_info/usecases/get_user_info_visibility_usecase.dart';

part 'get_user_info_visibility_usecase.provider.g.dart';

@riverpod
GetUserInfoVisibilityUseCase getUserInfoVisibilityUseCase(Ref ref) =>
    GetUserInfoVisibilityUseCase(ref.watch(userInfoRepositoryProvider));
