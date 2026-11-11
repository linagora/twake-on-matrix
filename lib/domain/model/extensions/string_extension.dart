extension StringExtension on String {
  String get ellipsizeFileName {
    return length > 30
        ? '${substring(0, 15)}...${substring(length - 15)}'
        : this;
  }

  String get safeFileName {
    final segments = split(RegExp(r'[/\\]')).where(
      (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
    );
    return segments.isEmpty ? 'file' : segments.join('_');
  }

  String get displayMentioned {
    return '@[$this]';
  }

  String get convertToHttps {
    if (startsWith('https://')) {
      return endsWith('/') ? this : '$this/';
    }
    if (startsWith('http://')) {
      final upgraded = replaceFirst('http://', 'https://');
      return upgraded.endsWith('/') ? upgraded : '$upgraded/';
    }
    return 'https://$this/';
  }
}
