extension StringExtension on String {
  String get ellipsizeFileName {
    return length > 30
        ? '${substring(0, 15)}...${substring(length - 15)}'
        : this;
  }

  String get displayMentioned {
    return '@[$this]';
  }

  String get convertToHttps {
    final domain = split(':').first;
    return 'https://$domain/';
  }
}
