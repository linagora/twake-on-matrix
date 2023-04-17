extension StringCasingExtension on String {
  String removeDiacritics() {
    const withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String str = this;
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }

    return str;
  }

  String getShortcutNameForAvatar() {
    final words = trim().split(RegExp('\\s+'));
    
    if (words.isEmpty || words[0] == '') {
      return '@';
    }

    final first = words[0];
    final last = words.length > 1 ? words[1] : '';
    final codeUnits = StringBuffer();
    
    if (first.isNotEmpty) {
      codeUnits.writeCharCode(first.runes.first);
    }
    
    if (last.isNotEmpty) {
      codeUnits.writeCharCode(last.runes.first);
    }

    return codeUnits.toString().toUpperCase();
  }
}
