import 'package:flutter/material.dart';

class TwakeToastWidget extends StatelessWidget {
  final String message;

  const TwakeToastWidget({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: Theme.of(context).colorScheme.inverseSurface,
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
      ),
    );
  }
}
