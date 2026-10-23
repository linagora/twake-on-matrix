import 'package:twake_chat/data/network/service_path.dart';

class DriveEndpoint {
  static final ServicePath tokenExchangeServicePath = ServicePath(
    '/auth/token_exchange',
  );

  static final ServicePath pickerSessionServicePath = ServicePath('/intents');

  static const String forceSessionIdQueryKey = 'force_session_id';
}

extension ServicePathDrive on ServicePath {
  /// Appends this path to [platformUrl], keeping its own path prefix and query.
  Uri resolveOn(
    Uri platformUrl, {
    Map<String, String> queryParameters = const {},
  }) {
    final mergedQuery = {...platformUrl.queryParameters, ...queryParameters};
    return platformUrl.replace(
      pathSegments: [
        ...platformUrl.pathSegments.where((segment) => segment.isNotEmpty),
        ...path.split('/').where((segment) => segment.isNotEmpty),
      ],
      queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
    );
  }
}
