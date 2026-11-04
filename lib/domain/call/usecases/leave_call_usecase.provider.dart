import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.dart';

part 'leave_call_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
LeaveCallUseCase leaveCallUseCase(Ref ref) =>
    LeaveCallUseCase(ref.watch(callRepositoryProvider));
