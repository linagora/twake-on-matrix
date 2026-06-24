const _fileExtensions = {
  // Documents
  'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
  'odt', 'ods', 'odp', 'txt', 'csv', 'tsv', 'rtf',
  // Markup / data
  'md', 'json', 'xml', 'yaml', 'yml', 'toml', 'ini', 'cfg', 'conf',
  // Images
  'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'bmp', 'ico', 'tiff',
  // Video / audio
  'mp4', 'mkv', 'avi', 'mov', 'webm', 'mp3', 'wav', 'ogg', 'flac', 'aac',
  // Archives
  'zip', 'tar', 'gz', 'bz2', 'xz', '7z', 'rar', 'pkg', 'dmg', 'iso',
  'apk', 'ipa', 'exe', 'msi',
  // Code
  'py', 'js', 'ts', 'jsx', 'tsx', 'dart', 'java', 'kt', 'swift',
  'go', 'rs', 'c', 'cpp', 'h', 'cs', 'php', 'rb', 'sh', 'bash',
  'zsh', 'fish', 'ps1', 'sql', 'html', 'css', 'scss',
  // Fonts
  'ttf', 'otf', 'woff', 'woff2',
  // Misc
  'log', 'lock', 'env',
};

bool _hasExplicitScheme(String url) =>
    url.startsWith('http://') || url.startsWith('https://');

bool _hasUrlStructuralIndicator(String url) =>
    url.contains('/') || url.contains('?') || url.contains('#');

bool _hasKnownFileExtension(String url) {
  final lastDot = url.lastIndexOf('.');
  if (lastDot == -1) return false;
  return _fileExtensions.contains(url.substring(lastDot + 1).toLowerCase());
}

/// Returns true if [url] looks like a filename falsely detected as a URL
/// by a linkify parser (e.g. "test.md" parsed as Moldova TLD).
///
/// Criteria:
/// - no explicit http/https scheme
/// - no path, query string, or fragment (structural URL indicators)
/// - last dot-delimited segment matches a known file extension
///   (multi-dot names like `my.report.pdf` or `archive.tar.gz` supported)
bool isFilenameUrl(String? url) {
  if (url == null) return false;
  if (url.isEmpty) return false;
  if (_hasExplicitScheme(url)) return false;
  if (_hasUrlStructuralIndicator(url)) return false;
  return _hasKnownFileExtension(url);
}
