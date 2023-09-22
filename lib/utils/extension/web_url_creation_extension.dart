import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

extension WebUrlCreationExtension on Uint8List {
  String toWebUrl() {
    final blob = html.Blob([this]);
    return html.Url.createObjectUrlFromBlob(blob);
  }
}
