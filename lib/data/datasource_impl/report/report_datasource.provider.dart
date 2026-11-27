import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/report/report_datasource.dart';
import 'package:twake_chat/data/datasource_impl/report/report_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'report_datasource.provider.g.dart';

@riverpod
ReportDatasource reportDatasource(Ref ref) =>
    ReportDatasourceImpl(ref.watch(activeMatrixClientProvider));
