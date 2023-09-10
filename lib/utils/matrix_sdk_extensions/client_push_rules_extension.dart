import 'package:matrix/matrix.dart';

extension ClientPushRulesExtension on Client {
  Future<void> setupUserDefinedPushRule({
    String scope = 'global',
    required String ruleId,
    List<PushCondition>? conditions,
    PushRuleKind kind = PushRuleKind.override,
    String? after,
    String? before,
  }) async {
    if (!containsRule(ruleId)) {
      await setPushRule(
        scope,
        kind,
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

  bool containsRule(String ruleId) {
    final rule = devicePushRules?.override?.firstWhere((PushRule rule) {
      return rule.ruleId == ruleId;
    });
    return rule?.ruleId == ruleId;
  }
}
