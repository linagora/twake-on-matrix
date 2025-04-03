import 'package:fluffychat/data/network/service_path.dart';

class TomEndpoint {
  static final ServicePath recoveryWordsServicePath = ServicePath(
    '/_twake/recoveryWords',
  );

  static final ServicePath addressbookServicePath = ServicePath(
    '/_twake/addressbook',
  );

  static final ServicePath invitationServicePath = ServicePath(
    '/invite',
  );

  static final ServicePath generateInvitationServicePath = ServicePath(
    '/invite/generate',
  );

  static const String twakeRootPath = '/_twake';

  static const String twakeAPIVersion = 'v1';
}

extension ServicePathTom on ServicePath {
  String generateTomEndpoint({
    String rootPath = TomEndpoint.twakeRootPath,
    String apiVersion = TomEndpoint.twakeAPIVersion,
  }) {
    return '$rootPath/$apiVersion$path';
  }
}
