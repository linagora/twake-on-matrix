import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/drive/policy/drive_links_message_policy.dart';

part 'drive_links_message_policy.provider.g.dart';

@Riverpod(keepAlive: true)
DriveLinksMessagePolicy driveLinksMessagePolicy(Ref ref) =>
    const DriveLinksMessagePolicy(requireHttps: true);
