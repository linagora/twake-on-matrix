import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class NoContactsFound extends StatelessWidget {

  final String keyword;

  const NoContactsFound({super.key, required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No results for "$keyword"',
          style: Theme.of(context).textTheme.titleLarge,),
        const SizedBox(height: 8.0,),
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                children: [
                  TextSpan(text: "• Make sure there are no typos in your search.\n"),
                  TextSpan(text: "• You might not have the user in your address book.\n"),
                  TextSpan(text: "• Check the contact access permission, the user might be in your contact list.\n"),
                  TextSpan(text: "• If the reason is not listed above, "),
                  TextSpan(
                    text: "seek help.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary
                    ),
                  )
                ],
              ),
            ]
          )
        )
      ],
    );
  }

}