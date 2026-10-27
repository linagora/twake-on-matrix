import 'dart:convert';
import 'dart:typed_data';

/// A plain 64x64 PNG.
final stickerFixtureBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAATUlEQVR42u3PQQkAAAgEsOuPnb0IvoXBCiw7eS0CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApcCCQexaQtDixEAAAAASUVORK5CYII=',
  ),
);

const stickerFixtureMimeType = 'image/png';

Map<String, Object?> stickerFixtureContent({
  required String body,
  required String url,
}) => {
  'body': body,
  'url': url,
  'info': {
    'mimetype': stickerFixtureMimeType,
    'size': stickerFixtureBytes.length,
    'w': 64,
    'h': 64,
  },
};
