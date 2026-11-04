import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/call/matrix_rtc_datasource.dart';
import 'package:twake_chat/data/datasource_impl/call/matrix_rtc_datasource_impl.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'matrix_rtc_datasource.provider.g.dart';

// Holds the membership timers of the ongoing call.
@Riverpod(keepAlive: true)
MatrixRtcDatasource matrixRtcDatasource(Ref ref) {
  final datasource = MatrixRtcDatasourceImpl(
    ref.watch(activeMatrixClientProvider),
  );
  ref.onDispose(datasource.dispose);
  return datasource;
}
