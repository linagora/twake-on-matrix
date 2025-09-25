import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/widgets/phone_book_loading/phone_book_loading_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class PhoneBookLoadingView extends StatelessWidget {
  final int progress;

  const PhoneBookLoadingView({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PhoneBookLoadingStyle.loadingPadding,
      child: Column(
        children: [
          Text(
            L10n.of(context)!.fetchingPhonebookContacts(progress),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: LinagoraRefColors.material().tertiary[20]),
          ),
          const SizedBox(height: ContactsTabViewStyle.loadingSpacer),
          LinearProgressIndicator(
            value: progress / 100,
          ),
        ],
      ),
    );
  }
}
