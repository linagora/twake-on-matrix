import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.provider.dart';

part 'twake_supported_provider.g.dart';

/// Session-wide: follows the ToM base url MatrixState sets.
@Riverpod(keepAlive: true)
bool twakeSupported(Ref ref) {
  final baseUrl = ref.watch(tomServerUrlInterceptorProvider).baseUrlListenable;
  baseUrl.addListener(ref.invalidateSelf);
  ref.onDispose(() => baseUrl.removeListener(ref.invalidateSelf));
  return baseUrl.value != null;
}
