import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'normalization_step.dart';

enum UnicodeDecomposition { nfd, nfkd }

class DiacriticStripStep extends NormalizationStep {
  final UnicodeDecomposition decomposition;

  const DiacriticStripStep({this.decomposition = UnicodeDecomposition.nfd});

  static final _combiningMarks = RegExp(r'\p{Mn}', unicode: true);

  @override
  String normalize(String input) {
    // NFD/NFKD leave ASCII untouched and ASCII has no combining marks.
    if (input.codeUnits.every((c) => c < 0x80)) return input;
    final decomposed = decomposition == UnicodeDecomposition.nfkd
        ? unorm.nfkd(input)
        : unorm.nfd(input);
    return decomposed.replaceAll(_combiningMarks, '');
  }
}
