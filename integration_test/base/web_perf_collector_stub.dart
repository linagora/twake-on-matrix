/// Non-web safeguard for the browser-only performance collector.
class WebPerfCollector {
  WebPerfCollector(String scenario);

  void start() => throw UnsupportedError('WebPerfCollector requires a browser');

  void checkpoint(String label, {Map<String, dynamic> extra = const {}}) =>
      throw UnsupportedError('WebPerfCollector requires a browser');

  void stop() => throw UnsupportedError('WebPerfCollector requires a browser');

  Future<void> flush([void Function(String)? logger]) =>
      throw UnsupportedError('WebPerfCollector requires a browser');
}
