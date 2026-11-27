import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_room_source.provider.dart';
import 'package:twake_chat/domain/scribe/usecases/set_scribe_enabled_usecase.dart';

part 'set_scribe_enabled_usecase.provider.g.dart';

@riverpod
SetScribeEnabledUseCase setScribeEnabledUseCase(Ref ref) =>
    SetScribeEnabledUseCase(ref.watch(scribeRoomSourceProvider));
