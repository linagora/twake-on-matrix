import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../text_search.dart';

class DiacriticStripStep implements NormalizationStep {
  const DiacriticStripStep();

  static final _combiningMarks = RegExp(r'\p{Mn}', unicode: true);

  @override
  String normalize(String input) =>
      unorm.nfd(input).replaceAll(_combiningMarks, '');
}