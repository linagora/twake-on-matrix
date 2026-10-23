import 'package:flutter_riverpod/flutter_riverpod.dart';

ProviderContainer? _current;

/// Disposes the previous container: integration tests re-run main() in one isolate.
ProviderContainer createAppProviderContainer() {
  _current?.dispose();
  return _current = ProviderContainer(retry: (_, _) => null);
}
