import 'package:matrix/matrix.dart';

/// No-op on non-web platforms. Mobile uses [BackgroundPush] instead.
Future<void> setupWebPush(Client client) async {}

Future<void> removeWebPush(Client client, {bool unsubscribe = true}) async {}

Future<bool> isWebPushActive() async => false;

Future<bool> isWebPushDisabledByUser() async => false;

bool isWebPushActiveSync() => false;

bool isWebPushPermissionDenied() => false;

Future<void> setWebPushEnabled(Client client, bool enabled) async {}
