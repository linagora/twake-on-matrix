// lib/data/cache/http_304_validator.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'model/cache_metadata.dart';

typedef OnCacheUpdated = void Function(String mxcUrl, Uint8List newBytes);

class Http304Validator {
  final http.Client _httpClient;
  final Set<String> _inProgress = {};
  final List<_ValidationTask> _queue = [];
  bool _isProcessing = false;

  OnCacheUpdated? onCacheUpdated;

  Http304Validator({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Schedule background revalidation (non-blocking)
  void scheduleRevalidation({
    required String mxcUrl,
    required Uri httpUri,
    required CacheMetadata metadata,
  }) {
    if (_inProgress.contains(mxcUrl)) return;

    _queue.add(
      _ValidationTask(mxcUrl: mxcUrl, httpUri: httpUri, metadata: metadata),
    );

    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    try {
      while (_queue.isNotEmpty) {
        assert(_queue.isNotEmpty, 'Queue became empty during processing');
        final task = _queue.removeAt(0);
        if (_inProgress.contains(task.mxcUrl)) continue;

        _inProgress.add(task.mxcUrl);
        try {
          await _validate(task);
        } finally {
          _inProgress.remove(task.mxcUrl);
        }

        // Backoff between requests
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _validate(_ValidationTask task) async {
    try {
      final headers = <String, String>{};

      // Add conditional headers
      if (task.metadata.etag != null) {
        headers['If-None-Match'] = task.metadata.etag!;
      }
      if (task.metadata.lastModified != null) {
        headers['If-Modified-Since'] = task.metadata.lastModified!;
      }

      final response = await _httpClient
          .get(task.httpUri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 304) {
        // Not modified - cache is valid
        Logs().d('HTTP304Validator: ${task.mxcUrl} not modified');
        return;
      }

      if (response.statusCode == 200) {
        // Content updated - notify listener
        Logs().d('HTTP304Validator: ${task.mxcUrl} has new content');
        onCacheUpdated?.call(task.mxcUrl, response.bodyBytes);
      }
    } catch (e) {
      // Silent fail - background validation shouldn't crash app
      Logs().d('HTTP304Validator: validation failed for ${task.mxcUrl}: $e');
    }
  }

  /// Check if content needs revalidation
  bool needsRevalidation(CacheMetadata metadata, Duration staleThreshold) {
    final age = DateTime.now().difference(metadata.createdAt);
    return age > staleThreshold;
  }

  void dispose() {
    _queue.clear();
    _inProgress.clear();
    _httpClient.close();
  }
}

class _ValidationTask {
  final String mxcUrl;
  final Uri httpUri;
  final CacheMetadata metadata;

  const _ValidationTask({
    required this.mxcUrl,
    required this.httpUri,
    required this.metadata,
  });
}
