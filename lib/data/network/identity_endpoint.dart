import 'package:fluffychat/data/network/service_path.dart';

class IdentityEndpoint {
  static const String matrixIdentityRootPath = '/_matrix/identity';
  static const String matrixIdentityAPIVersion = 'v2';

  static const String twakeIdentityRootPath = '/_twake/identity';
  static const String twakeIdentityAPIVersion = 'v1';

  static final ServicePath matchUserIdServicePath = ServicePath(
    '/lookup/match',
  );
}

extension ServicePathExtensions on ServicePath {
  String generateTwakeIdentityEndpoint({
    String rootPath = IdentityEndpoint.twakeIdentityRootPath,
    String apiVersion = IdentityEndpoint.twakeIdentityAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }
}