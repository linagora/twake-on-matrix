import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/report/report_repository.provider.dart';
import 'package:twake_chat/domain/report/usecases/report_room_usecase.dart';

part 'report_room_usecase.provider.g.dart';

@riverpod
ReportRoomUseCase reportRoomUseCase(Ref ref) =>
    ReportRoomUseCase(ref.watch(reportRepositoryProvider));
