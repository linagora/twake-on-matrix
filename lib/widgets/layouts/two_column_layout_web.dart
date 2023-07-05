import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwoColumnLayoutWeb extends StatelessWidget {

  final Widget mainView;

  final Widget sideView;

  const TwoColumnLayoutWeb({
    super.key,
    required this.mainView,
    required this.sideView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 0, right: 16.0, top: 16.0, bottom: 16.0),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(16.0)),
            child: Container(
              width: 376,
              decoration: BoxDecoration(
                color: LinagoraRefColors.material().primary[100],
              ),
              child: mainView,
            ),
          ),
          const SizedBox(width: 16,),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16.0)),
              child: Container(
                decoration: BoxDecoration(
                  color: LinagoraRefColors.material().primary[100],
                ),
                child: sideView,
              ),
            ),
          ),
        ],
      ),
    );
  }
}