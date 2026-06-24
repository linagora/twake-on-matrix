import 'package:matrix/matrix.dart';

/// No-op on non-web platforms. Mobile uses [BackgroundPush] instead.
Future<void> setupWebPush(Client client) async {}

Future<void> removeWebPush(Client client, {bool unsubscribe = true}) async {}
