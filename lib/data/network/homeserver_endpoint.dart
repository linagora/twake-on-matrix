import 'package:fluffychat/data/network/service_path.dart';

class HomeserverEndpoint {
  static const String homeserverMediaPath = '/_matrix/media';
  static const String homeserverAPIVersion = 'v3';

  static final ServicePath uploadMediaServicePath = ServicePath(
    '/upload',
  );
}

extension ServicePathHomeserver on ServicePath {
  String generateHomeserverIdentityEndpoint({
    String rootPath = HomeserverEndpoint.homeserverMediaPath,
    String apiVersion = HomeserverEndpoint.homeserverAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }
}