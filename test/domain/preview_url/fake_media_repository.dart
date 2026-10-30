import 'dart:async';

import 'package:twake_chat/domain/model/media/url_preview.dart';
import 'package:twake_chat/domain/repository/media/media_repository.dart';

class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository({this.onGetUrlPreview});

  Future<UrlPreview> Function(Uri uri)? onGetUrlPreview;

  final List<({Uri uri, int? preferredPreviewTime})> calls = [];

  @override
  Future<UrlPreview> getUrlPreview({
    required Uri uri,
    int? preferredPreviewTime,
  }) {
    calls.add((uri: uri, preferredPreviewTime: preferredPreviewTime));
    final handler = onGetUrlPreview;
    if (handler == null) return Future.value(UrlPreview(title: uri.host));
    return handler(uri);
  }
}
