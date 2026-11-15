import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/sources/web_auth_launcher.dart';

part 'web_auth_launcher.provider.g.dart';

@Riverpod(keepAlive: true)
WebAuthLauncher webAuthLauncher(Ref ref) => const FlutterWebAuth2Launcher();
