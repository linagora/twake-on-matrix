import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/drive/policy/drive_platform_url_policy.dart';

part 'drive_platform_url_policy.provider.g.dart';

@Riverpod(keepAlive: true)
DrivePlatformUrlPolicy drivePlatformUrlPolicy(Ref ref) =>
    const DrivePlatformUrlPolicy();
