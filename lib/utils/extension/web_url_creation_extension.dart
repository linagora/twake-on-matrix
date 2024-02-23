import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

extension WebUrlCreationExtension on Uint8List {
  String toWebUrl({required String mimeType}) {
    final blob = html.Blob([this], mimeType);
    return html.Url.createObjectUrlFromBlob(blob);
  }
}
