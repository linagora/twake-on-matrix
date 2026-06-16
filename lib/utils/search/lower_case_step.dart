import 'package:fluffychat/domain/model/search/normalization_step.dart';

class LowerCaseStep extends NormalizationStep {
  const LowerCaseStep();

  @override
  String normalize(String input) => input.toLowerCase();
}