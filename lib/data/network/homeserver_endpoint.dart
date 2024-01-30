import 'package:fluffychat/data/network/service_path.dart';

class HomeserverEndpoint {
  static const String homeserverMediaPath = '/_matrix/media';
  static const String homeserverAPIVersion = 'v3';
  static const String homeserverClientPath = '/_matrix/client';

  static final ServicePath uploadMediaServicePath = ServicePath(
    '/upload',
  );

  static final ServicePath getPreviewUrlServicePath = ServicePath(
    '/preview_url',
  );

  static final ServicePath searchPath = ServicePath(
    '/search',
  );

  static final ServicePath configPath = ServicePath(
    '/config',
  );
}

extension ServicePathHomeserver on ServicePath {
  String generateHomeserverMediaEndpoint({
    String rootPath = HomeserverEndpoint.homeserverMediaPath,
    String apiVersion = HomeserverEndpoint.homeserverAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }

  String generateHomeserverConfigEndpoint({
    String rootPath = HomeserverEndpoint.homeserverMediaPath,
    String apiVersion = HomeserverEndpoint.homeserverAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }

  String generateHomeserverServerSearchPath({
    String rootPath = HomeserverEndpoint.homeserverClientPath,
    String apiVersion = HomeserverEndpoint.homeserverAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }
}
