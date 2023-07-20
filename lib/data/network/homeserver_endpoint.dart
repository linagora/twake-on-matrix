import 'package:fluffychat/data/network/service_path.dart';

class HomeserverEndpoint {
  static const String homeserverRootPath = '/_matrix/media';
  static const String homeserverAPIVersion = 'v3';

  static final ServicePath uploadMediaServicePath = ServicePath(
    '/upload',
  );
}

extension ServicePathHomeserver on ServicePath {
  String generateTwakeIdentityEndpoint({
    String rootPath = HomeserverEndpoint.homeserverRootPath,
    String apiVersion = HomeserverEndpoint.homeserverAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }
}