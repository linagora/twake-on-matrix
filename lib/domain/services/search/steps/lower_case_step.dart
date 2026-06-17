import 'normalization_step.dart';

class LowerCaseStep extends NormalizationStep {
  const LowerCaseStep();

  @override
  String normalize(String input) => input.toLowerCase();
}
