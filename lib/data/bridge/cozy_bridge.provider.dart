import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/bridge/platform_cozy_bridge.dart';
import 'package:twake_chat/data/bridge/cozy_bridge.dart';

part 'cozy_bridge.provider.g.dart';

@Riverpod(keepAlive: true)
CozyBridge cozyBridge(Ref ref) => const PlatformCozyBridge();
