import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class NoContactsFound extends StatelessWidget {
  final String? keyword;

  const NoContactsFound({super.key, this.keyword});

  @override
  Widget build(BuildContext context) {
    return keyword != null
        ? const Align(
            alignment: Alignment.center,
            child: EmptySearchWidget(),
          )
        : SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: Align(
              child: Text(
                L10n.of(context)!.youDontHaveAnyContactsYet,
              ),
            ),
          );
  }
}
