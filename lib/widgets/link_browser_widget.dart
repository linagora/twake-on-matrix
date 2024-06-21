import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

class LinkBrowserWidget extends StatelessWidget {
  final Uri uri;
  final Widget child;

  const LinkBrowserWidget({super.key, required this.uri, required this.child});

  @override
  Widget build(BuildContext context) {
    return Link(uri: uri, builder: (context, function) => child);
  }
}
