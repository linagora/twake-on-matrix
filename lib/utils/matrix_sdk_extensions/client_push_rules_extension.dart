import 'package:matrix/matrix.dart';

extension ClientPushRulesExtension on Client {
  Future<void> setupUserDefinedPushRule({
    required String ruleId,
    List<PushCondition>? conditions,
    String? after,
    String? before,
  }) async {
    await setPushRule(
      'global',
      PushRuleKind.underride,
      ruleId,
      [
        PushRuleAction.notify,
        {"set_tweak": "sound", "value": "default"}
      ],
      conditions: conditions,
      after: after,
      before: before,
    );
  }
}
