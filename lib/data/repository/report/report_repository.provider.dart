import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/report/report_datasource.provider.dart';
import 'package:twake_chat/data/repository/report/report_repository_impl.dart';
import 'package:twake_chat/domain/repository/report/report_repository.dart';

part 'report_repository.provider.g.dart';

@riverpod
ReportRepository reportRepository(Ref ref) =>
    ReportRepositoryImpl(ref.watch(reportDatasourceProvider));
