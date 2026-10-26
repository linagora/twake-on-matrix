import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

ProviderContainer? _current;

/// Disposes the previous container: integration tests re-run main() in one isolate.
///
/// [overrides] are the values `main` knows before the first frame (the boot
/// clients and the boot snapshot); nothing can be overridden once the
/// container exists.
ProviderContainer createAppProviderContainer({
  List<Override> overrides = const [],
}) {
  _current?.dispose();
  return _current = ProviderContainer(
    retry: (_, _) => null,
    overrides: overrides,
  );
}
