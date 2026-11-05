// `Uri.parse('host:8443')` reads `host` as the scheme, so add it first.
Uri parseHomeserverInput(String input) =>
    Uri.parse(input.contains('://') ? input : 'https://$input');
