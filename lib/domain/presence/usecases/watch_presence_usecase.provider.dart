import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/presence/repositories/presence_repository_impl.provider.dart';
import 'package:twake_chat/domain/presence/usecases/watch_presence_usecase.dart';

part 'watch_presence_usecase.provider.g.dart';

@riverpod
WatchPresenceUseCase watchPresenceUseCase(Ref ref) =>
    WatchPresenceUseCase(ref.watch(presenceRepositoryProvider));
