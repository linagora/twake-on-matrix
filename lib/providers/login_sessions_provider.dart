import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/login_sessions.dart';

part 'login_sessions_provider.g.dart';

/// The sessions of the unlogged clients that the login screens use; the one
/// source for them. `MatrixState` attaches its login host in `initState` and
/// releases it in `dispose`.
@Riverpod(keepAlive: true)
LoginSessions loginSessions(Ref ref) => LoginSessions();
