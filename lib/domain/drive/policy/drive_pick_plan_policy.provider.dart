import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/drive/policy/drive_pick_plan_policy.dart';

part 'drive_pick_plan_policy.provider.g.dart';

@Riverpod(keepAlive: true)
DrivePickPlanPolicy drivePickPlanPolicy(Ref ref) =>
    const DrivePickPlanPolicy(requireHttps: true);
