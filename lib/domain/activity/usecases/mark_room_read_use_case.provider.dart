import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/activity/usecases/mark_room_read_use_case.dart';

part 'mark_room_read_use_case.provider.g.dart';

@riverpod
MarkRoomReadUseCase markRoomReadUseCase(Ref ref) =>
    MarkRoomReadUseCase(ref.watch(activityRepositoryProvider));
