import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/report/report_repository.provider.dart';
import 'package:twake_chat/domain/report/usecases/report_user_usecase.dart';

part 'report_user_usecase.provider.g.dart';

@riverpod
ReportUserUseCase reportUserUseCase(Ref ref) =>
    ReportUserUseCase(ref.watch(reportRepositoryProvider));
