import 'package:fluffychat/data/network/service_path.dart';

class TomEndpoint {
  static final ServicePath recoveryWordsServicePath = ServicePath(
    '/_twake/recoveryWords',
  );

  static final ServicePath addressbookServicePath = ServicePath(
    '/_twake/addressbook',
  );
}
