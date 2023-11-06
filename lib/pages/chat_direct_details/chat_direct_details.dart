import 'package:flutter/material.dart';

class ChatDirectDetails extends StatefulWidget {
  const ChatDirectDetails({super.key});

  @override
  State<ChatDirectDetails> createState() => ChatDirectDetailsController();
}

class ChatDirectDetailsController extends State<ChatDirectDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('"Chat detail"')),
      body: const SizedBox.shrink(),
    );
  }
}
