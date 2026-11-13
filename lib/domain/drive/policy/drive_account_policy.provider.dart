import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/drive/policy/drive_account_policy.dart';

part 'drive_account_policy.provider.g.dart';

@Riverpod(keepAlive: true)
DriveAccountPolicy driveAccountPolicy(Ref ref) => const DriveAccountPolicy();
