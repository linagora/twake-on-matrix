import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_picked_entry.freezed.dart';

@freezed
abstract class DrivePickedEntry with _$DrivePickedEntry {
  const DrivePickedEntry._();

  const factory DrivePickedEntry({
    required String id,
    required String name,
    required int size,
    String? mimeType,
    Uri? sharingLink,
    Uri? downloadLink,
    Uri? thumbnailLink,
  }) = _DrivePickedEntry;

  String get mimeTypeOrDefault => mimeType ?? 'application/octet-stream';

  /// Returns null when the document cannot be used safely.
  ///
  /// An unsafe thumbnail only removes the thumbnail, never the document.
  static DrivePickedEntry? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final identity = _identityOf(json);
    final links = _linksOf(json);
    if (identity == null || links == null) return null;
    return DrivePickedEntry(
      id: identity.id,
      name: identity.name,
      size: identity.size,
      mimeType: _nonBlankString(json['mimeType']),
      sharingLink: links.sharing,
      downloadLink: links.download,
      thumbnailLink: links.thumbnail,
    );
  }

  static final Uri _invalid = Uri();

  static ({String id, String name, int size})? _identityOf(
    Map<String, dynamic> json,
  ) {
    final id = _nonBlankString(json['id']);
    final name = _nonBlankString(json['name']);
    final size = _nonNegativeSize(json['size']);
    if (id == null || name == null) return null;
    if (size == null) return null;
    return (id: id, name: name, size: size);
  }

  static ({Uri? sharing, Uri? download, Uri? thumbnail})? _linksOf(
    Map<String, dynamic> json,
  ) {
    final sharing = _optionalHttpsUri(json['sharingLink']);
    final download = _optionalHttpsUri(json['downloadLink']);
    if (sharing == _invalid || download == _invalid) return null;
    if (sharing == null && download == null) return null;
    final thumbnail = _thumbnailLinkOf(json['thumbnail']);
    return (
      sharing: sharing,
      download: download,
      thumbnail: thumbnail == _invalid ? null : thumbnail,
    );
  }

  static Uri? _thumbnailLinkOf(Object? thumbnail) =>
      thumbnail is Map<String, dynamic>
      ? _optionalHttpsUri(thumbnail['link'])
      : null;

  static int? _nonNegativeSize(Object? value) =>
      value is num && value >= 0 ? value.toInt() : null;

  static String? _nonBlankString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  /// Null when absent, [_invalid] when present but not a valid https URL.
  static Uri? _optionalHttpsUri(Object? value) {
    if (value == null) return null;
    final uri = value is String ? Uri.tryParse(value) : null;
    return uri != null && _isHttps(uri) ? uri : _invalid;
  }

  static bool _isHttps(Uri uri) => uri.isScheme('https') && uri.host.isNotEmpty;
}
