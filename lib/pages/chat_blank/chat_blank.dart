import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/pages/chat_blank/chat_blank_style.dart';
import 'package:fluffychat/presentation/mixins/go_to_group_chat_mixin.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatBlank extends StatelessWidget {
  final bool loading;

  const ChatBlank({this.loading = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add invisible appbar to make status bar on Android tablets bright.
      backgroundColor: LinagoraSysColors.material().onPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: LinagoraSysColors.material().onPrimary,
      ),
      extendBodyBehindAppBar: true,
      body: loading
          ? _ChatBlankLoading(context: context)
          : _ChatBlankNotChat(context: context),
    );
  }
}

class _ChatBlankNotChat extends StatelessWidget {
  const _ChatBlankNotChat({
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Hero(
            tag: 'info-logo',
            child: SvgPicture.asset(
              ImagePaths.icEmptyPage,
            ),
          ),
        ),
        Padding(
          padding: ChatBlankStyle.elementsPadding,
          child: Text(
            L10n.of(context)!.notInAChatYet,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        _ChatBlankRichText(context: context),
      ],
    );
  }
}

class _ChatBlankRichText extends StatelessWidget with GoToGroupChatMixin {
  const _ChatBlankRichText({
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: _buildInlineSpans(context),
      ),
    );
  }

  List<InlineSpan> _buildInlineSpans(BuildContext context) {
    final List<InlineSpan> inlineSpans = L10n.of(context)!
        .blankChatTitle
        .splitMapJoinToList<InlineSpan>(
          RegExp(r'#EditIcon#'),
          onMatch: (_) => _buildIconTitle(context),
          onNonMatch: (text) =>
              TextSpan(text: text, style: ChatBlankStyle.textStyle(context)),
        );
    return inlineSpans;
  }

  WidgetSpan _buildIconTitle(BuildContext context) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.chat),
            onPressed: goToNewPrivateChat,
            child: Text(L10n.of(context)!.newDirectMessage),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.group),
            onPressed: () => goToNewGroupChat(
              innerNavigatorContext(),
            ),
            child: Text(L10n.of(context)!.newChat),
          ),
        ],
        style: const MenuStyle(
          alignment: Alignment.topLeft,
        ),
        builder: (context, menuController, _) {
          return InkWell(
            onTap: () => menuController.open(),
            child: Icon(
              Icons.mode_edit_outline_outlined,
              size: ChatBlankStyle.iconSize,
              color: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  bool get goRouteAvailableInFirstColumn =>
      FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn();

  BuildContext innerNavigatorContext() {
    if (!goRouteAvailableInFirstColumn) {
      return FirstColumnInnerRoutes
          .innerNavigatorNotOneColumnKey.currentState!.context;
    } else {
      return FirstColumnInnerRoutes
          .innerNavigatorOneColumnKey.currentState!.context;
    }
  }

  void goToNewPrivateChat() {
    if (!goRouteAvailableInFirstColumn) {
      innerNavigatorContext().pushInner('innernavigator/newprivatechat');
    } else {
      innerNavigatorContext().push('/rooms/newprivatechat');
    }
  }
}

class _ChatBlankLoading extends StatelessWidget {
  const _ChatBlankLoading({
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: ChatBlankStyle.width(context),
        child: const LinearProgressIndicator(),
      ),
    );
  }
}
