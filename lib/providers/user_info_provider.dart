import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/user_info/usecases/get_user_info_usecase.provider.dart';

part 'user_info_provider.g.dart';

@riverpod
Future<UserInfo> userInfo(Ref ref, String userId) =>
    ref.watch(getUserInfoUseCaseProvider).execute(userId);
