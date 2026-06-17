import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'normalization_step.dart';

class DiacriticStripStep extends NormalizationStep {
  const DiacriticStripStep();

  static final _combiningMarks = RegExp(r'\p{Mn}', unicode: true);

  @override
  String normalize(String input) =>
      unorm.nfd(input).replaceAll(_combiningMarks, '');
}
