import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';

class LoadingContactWidget extends StatelessWidget {
  const LoadingContactWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            height: 16.0,
          ),
          const CircularProgressIndicator(),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            L10n.of(context)!.loadingContacts,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
      ),
    );
  }
}
