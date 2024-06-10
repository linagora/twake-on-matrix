import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class NoContactsFound extends StatelessWidget {
  final String? keyword;

  const NoContactsFound({super.key, this.keyword});

  @override
  Widget build(BuildContext context) {
    return keyword != null
        ? Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.of(context)!.noResultForKeyword(keyword!),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(
                  height: 8.0,
                ),
                Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        children: [
                          TextSpan(
                            text: L10n.of(context)!.searchResultNotFound1,
                          ),
                          TextSpan(
                            text: L10n.of(context)!.searchResultNotFound2,
                          ),
                          TextSpan(
                            text: L10n.of(context)!.searchResultNotFound3,
                          ),
                          TextSpan(
                            text: L10n.of(context)!.searchResultNotFound4,
                          ),
                          TextSpan(
                            text: L10n.of(context)!.searchResultNotFound5,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                const Align(
                  alignment: Alignment.center,
                  child: EmptySearchWidget(),
                ),
              ],
            ),
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
